





hwnd: HWND;
width: int;
height: int;

main :: () {
  set_cwd_to_exe_location(); // ensures we read and write files next to the exe, whereever it is

  // you can run the cmd with a width and height
  // crosshair.exe 32 32
  width = string_to_int(cmd_arg(1, default="24"));
  height = string_to_int(cmd_arg(2, default=tprint("%", width)));

  // create the main window
  hwnd = create_window(
    window_name          = "Crosshair",
    width                = width,
    height               = height,
    window_x             = Monitor.size(hwnd).w / 2 - width/2,
    window_y             = Monitor.size(hwnd).h / 2 - height/2,
    background_color_rgb = .[0,0,0],
    style                = WS_POPUP,
    style_ex             = WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TRANSPARENT
  );

  window_make_transparent_background(hwnd);

  // init Simp rendering stuff
  Simp.set_render_target(hwnd);

  //
  init_texture();

  // main game loop
  while 1 {
    update();
    render(); // :render_once
    tfree();
    sleep_milliseconds(1000);
  }
}

window_make_transparent_background :: (hwnd: HWND) {
  colorref : COLORREF : 0x00000000;
  SetLayeredWindowAttributes(hwnd, colorref, 255, LWA_COLORKEY);
}

crosshair_texture: Simp.Texture;
init_texture :: () {
  if(file_exists("crosshair.png")) {
    Simp.texture_load_from_file(*crosshair_texture, "crosshair.png");
  } else {
    png_bytes :: #run embed_file("src/bin/aim.png");
    Simp.texture_load_from_memory(*crosshair_texture, png_bytes);
  }
}


update :: () {
  update_window_events(); for * event : events_this_frame {
    if(event.type == .QUIT) exit(0);
  }
}




// :render_once
// if we try to call render only once it does mostly work
// except sometimes, like when launching a game, all your windows flash
// and it results our window and deletes the crosshair, so we need to re-render constantly
render :: () {
  Simp.set_shader_for_images(*crosshair_texture);

  {
    x :: 0;
    y :: 0;
    w : float = xx width;
    h : float = xx height;
    Simp.immediate_quad(x, y, w, h, .{1, 1, 1, 1});
  }

  Simp.swap_buffers(hwnd);
  DwmFlush(); // simp opengl vsync burns 100% cpu without this
  Simp.update_window(hwnd);
  Simp.clear_render_target(0, 0, 0, 0);
}










#import "Basic";
#import,file "modules/mybasic.jai";

#import "Windows";
  COLORREF :: DWORD;

  Dwmapi   :: #system_library "Dwmapi";
  DwmFlush :: () -> HRESULT #foreign Dwmapi;

  user32      :: #system_library "user32";
  SetLayeredWindowAttributes :: (hwnd: HWND, crkey: COLORREF, balpha: u8, dwflags: DWORD) -> BOOL #foreign user32;
  LWA_ALPHA    :: 0x02;
  LWA_COLORKEY :: 0x01;

#import,dir "modules/Window_Creation"; // custom window creation so i can pass style_ex i guess?
#import "Input";

#import "File_Utilities";

Simp :: #import "Simp";


// Monitor.size(hwnd) memoizes the size the first time it's called.
// this probably has issues with multiple monitors
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
