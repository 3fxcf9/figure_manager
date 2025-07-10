module main

import os
import cli { Command, Flag }

// #include <unistd.h>
//
// fn C.setsid() int

const editor_name = 'inkscape'

struct Paths {
	figure_path           string
	resized_figure_path   string
	optimized_figure_path string
}

fn go_background() {
	if os.fork() > 0 {
		exit(0)
	}
	// C.setsid()
	// second fork
	if os.fork() > 0 {
		exit(0)
	}
	os.write_file('/tmp/figure‑manager‑watcher.pid', '${os.getpid()}') or {
		panic('Error creating pid file')
	}
}

fn main() {
	mut app := Command{
		name:        'figure-manager'
		description: 'TODO'
		commands:    [
			Command{
				name:          'create'
				usage:         '<path> <name>'
				required_args: 2
				execute:       create
			},
			Command{
				name:          'edit'
				usage:         '<path>'
				required_args: 1
				execute:       edit
				flags:         [
					Flag{
						flag:        .string
						name:        'name'
						description: 'The figure name (same as the filename without hyphen)'
					},
				]
			},
		]
	}
	app.setup()
	app.parse(os.args)
}

fn convert_figure_name_to_filename(figure_name string, modifier ?string) string {
	if m := modifier {
		return figure_name.to_lower().replace(' ', '-') + '_${m}.svg'
	}
	return figure_name.to_lower().replace(' ', '-') + '.svg'
}

fn convert_filename_to_figure_name(filename string) string {
	_, name, _ := os.split_path(filename)
	return name.all_before_last('_').replace('-', ' ').title()
}

fn choice(options []string, prompt ?string) string {
	prompt_option := if p := prompt { '--prompt-text=${p}' } else { '' }
	return (os.execute_opt('echo "${options.join('\n')}" | tofi ${prompt_option}') or {
		os.Result{
			output: options[0]
		}
	}).output
}

fn create(cmd Command) ! {
	figure_folder_path, figure_name := cmd.args[0], cmd.args[1]

	if !os.exists(figure_folder_path) {
		os.mkdir_all(figure_folder_path) or { error('error while creating the figure folder') }
	}

	figure_path := os.join_path_single(figure_folder_path, convert_figure_name_to_filename(figure_name,
		none))
	resized_figure_path := os.join_path_single(figure_folder_path, convert_figure_name_to_filename(figure_name,
		'resized'))
	optimized_figure_path := os.join_path_single(figure_folder_path, convert_figure_name_to_filename(figure_name,
		'optimized'))

	if os.exists(figure_path) {
		println(figure_name) // Not to delete the current vim line
		exit(3)
	}

	config_dir := os.config_dir() or { return error('failed to locate config folder') }

	template_path := os.join_path(config_dir, 'course-manager', 'template.svg')
	if !os.exists(template_path) {
		return error('unable to find the template file')
	}

	os.cp(template_path, figure_path) or { return error('error while copying the template file') }

	// Write the figure include code
	println('%fig ${figure_name}
          |    @[${optimized_figure_path}]
          |%'.strip_margin())

	go_background()

	watch(figure_path, resized_figure_path, optimized_figure_path)
}

fn edit(cmd Command) ! {
	figure_folder_path := cmd.args[0]

	n := cmd.flags.get_string('name') or { '' }
	mut selected_figure := ''
	if !n.is_blank() {
		selected_figure = n
	} else {
		files := os.ls(figure_folder_path) or { [] }

		mut figure_list := []string{}

		for f in files {
			figure_name := convert_filename_to_figure_name(f)
			if figure_name !in figure_list {
				figure_list << figure_name
			}
		}
		selected_figure = choice(figure_list, '󰇞').trim_space()
	}

	figure_path := os.join_path_single(figure_folder_path, convert_figure_name_to_filename(selected_figure,
		none))
	resized_figure_path := os.join_path_single(figure_folder_path, convert_figure_name_to_filename(selected_figure,
		'resized'))
	optimized_figure_path := os.join_path_single(figure_folder_path, convert_figure_name_to_filename(selected_figure,
		'optimized'))

	// Going background
	go_background()

	watch(figure_path, resized_figure_path, optimized_figure_path)
}

fn watch(figure_path string, resized_figure_path string, optimized_figure_path string) {
	// Start editor
	editor_path := os.find_abs_path_of_executable(editor_name) or { panic('editor not found') }
	mut editor := os.new_process(editor_path)
	editor.set_args([figure_path])
	editor.run()

	// Watch for change in a thread that will be closed when the editor process finishes
	go fn [figure_path, resized_figure_path, optimized_figure_path] (mut editor os.Process) {
		folder, _, _ := os.split_path(figure_path)
		for editor.is_alive() {
			// Block until a change is detected
			result := os.execute('inotifywait --quiet -e close_write --format "%w%f" ${folder}')

			if result.exit_code != 0 {
				// inotifywait error or folder removed
				break
			}

			changed := result.output.trim_space()
			if os.real_path(changed) != os.real_path(figure_path) {
				continue
			}

			// Resize
			os.execute_opt('inkscape --export-plain-svg --export-area-drawing ' +
				'${figure_path} -o ${resized_figure_path}') or {
				eprintln('Resize failed, copying raw')
				os.cp(figure_path, resized_figure_path) or { panic(err) }
			}

			// Optimize
			os.execute_opt('scour --quiet --strip-xml-prolog --enable-comment-stripping ' +
				'-i ${resized_figure_path} -o ${optimized_figure_path}') or {
				eprintln('Optimize failed, copying resized')
				os.cp(resized_figure_path, optimized_figure_path) or { panic(err) }
			}
		}
	}(mut editor)

	editor.wait()
}
