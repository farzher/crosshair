RELEASE :: #run get_build_options().array_bounds_check == .OFF;
main_filepath :: "src/main.jai";
exe_icon_path :: "src/bin/tray.ico";
exe_name      :: "crosshair";

#run build();
build :: () {

  // seperate build options for debug vs release
  build_options((options: *Build_Options) {;
    options.output_executable_name = exe_name;

    #if !RELEASE then options.output_path = "src/bin/";
    #if !RELEASE then options.backend = .X64;

    #if  RELEASE then options.emit_debug_info = .NONE;
    #if  RELEASE then options.output_path = "./";
    #if  RELEASE then #run Windows_Resources.disable_runtime_console();
  });

  // wait for the exe to finish compiling, so we can set its icon
  build_compile(main_filepath);

  // set exe icon
  exe_path := tprint("%1%2.exe", options.output_path, options.output_executable_name);
  Windows_Resources.set_icon_by_filename(exe_path, exe_icon_path);
}







#import "Basic";
#import "Compiler";
#import "String";
Windows_Resources :: #import "Windows_Resources";
File              :: #import "File";

w: Workspace;
options: Build_Options;
build_inited := false;
build_ensure_init :: () {
  if build_inited return; build_inited = true;
  w       = compiler_create_workspace();
  options = get_build_options();
  set_build_options_dc(.{do_output=false});
}
build_options :: (fn: (*Build_Options)) {
  build_ensure_init();
  fn(*options);
  set_build_options(options, w);
}
build_add_import_dir :: (options: *Build_Options, dir: string) {
  import_path: [..] string;
  array_add(*import_path, dir);
  array_add(*import_path, ..options.import_path);
  options.import_path = import_path;
}
build_compile :: (src_files: ..string) {
  build_ensure_init();

  compiler_begin_intercept(w);

  for src_files  add_build_file(it, w);

  // actually compile the code, and wait for it to finish compiling
  while true {
    message := compiler_wait_for_message();
    if !message continue;
    if message.workspace != w continue;
    if message.kind == .COMPLETE break;
  }

  compiler_end_intercept(w);
}
