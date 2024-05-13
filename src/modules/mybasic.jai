/* -farzher September 13, 2021
  just a collection of common functions i use
*/



// using #import "Basic";
#import "Basic";

#import "String";
mylog :: (args:..Any, to_standard_error := false) {
  if args.count == 0 { print("\n", to_standard_error=to_standard_error); return; }

  formatstr: string;
  push_tallocator();
  for args  formatstr = join(formatstr, "% ");
  formatstr[formatstr.count-1] = #char "\n"; // replace the trailing space with a newline
  print(formatstr, ..args, to_standard_error=to_standard_error);
}

die :: (args: ..Any) {
  mylog("[Fatal Error]", to_standard_error=true);
  mylog(..args, to_standard_error=true);
  exit(1);
}






#scope_file
Compiler :: #import "Compiler";
#scope_export
RELEASE :: #run Compiler.get_build_options().array_bounds_check == .OFF;

tallocator :: __temporary_allocator;
tfree :: reset_temporary_storage;
tget :: get_temporary_storage_mark;
tset :: set_temporary_storage_mark;
push_trelease :: auto_release_temp;
push_treset :: auto_release_temp;
push_tallocator :: () #expand {
  old_allocator           := context.allocator;
  `defer context.allocator = old_allocator;

  context.allocator        = tallocator;
};


set_cwd_to_exe_location :: () {
  system :: #import "System";
  String :: #import "String";
  set_working_directory(String.path_strip_filename(system.get_path_of_running_executable()));
}

embed_file :: (file_path: string) -> []u8 {
  File :: #import "File";
  return xx File.read_entire_file(file_path);
}



// return the positional argument at index
// skips over / ignores non-positional arguments ex: -sleepms
cmd_arg :: (index: int, default: string = "") -> string {
  args_i_care_about: [..]string;
  args_i_care_about.allocator = temp;
  for arg, i: get_command_line_arguments() {
    // the first arg, the exe name, is always allowed, even if it starts with a -
    if i > 0 {
      begins_with_dash := find_index_from_left(arg, "-") == 0;
      if begins_with_dash continue;
    }
    array_add(*args_i_care_about, arg);
  }

  if index >= args_i_care_about.count return default;
  return args_i_care_about[index];
}

// return the value of a named argument ex: -sleepms=0
cmd_arg :: (varname: string, default: int = 0) -> int {
  #import "String";
  for arg: get_command_line_arguments() {
    if arg == tprint("-%", varname) return 1;
    if begins_with(arg, tprint("-%=", varname)) {
      valstr := substr(arg, 1+varname.count+1);
      return parse_int(*valstr);
    }
  }
  return default;
}

substr :: inline (str: string, index: int, count: int = 0) -> string #must {
  if count == 0 count = str.count - index;

  c: string = ---;
  c.data = str.data + index;
  c.count = count;
  return c;
}


// Monitor.size(hwnd) memoizes the size the first time it's called.
// this probably has issues with multiple monitors
#import "Windows";
Monitor: struct {

  _size: struct {x, y, w, h :s32;};
  size :: (hwnd: HWND) -> type_of(_size) { ensure_init(hwnd); return Monitor._size; }

  init :: (hwnd: HWND) {
    info: MONITORINFO = ---;
    info.cbSize = size_of(type_of(info));
    success := GetMonitorInfoW(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), *info);
    if !success  die("failed to get monitor size");

    Monitor._size.x = info.rcMonitor.left;
    Monitor._size.y = info.rcMonitor.top;
    Monitor._size.w = info.rcMonitor.right - Monitor._size.x;
    Monitor._size.h = info.rcMonitor.bottom - Monitor._size.y;
  }

  ensure_init :: (hwnd: HWND) {
    if Monitor._size.w != 0  return;
    Monitor.init(hwnd);
  }
}
