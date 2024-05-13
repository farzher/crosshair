





hwnd: HWND;
width: int;
height: int;

main :: () {
  set_cwd_to_exe_location(); // ensures we read and write files next to the exe, whereever it is

  // create the main window
  // we don't know what size to make it yet ...
  hwnd = create_window(
    window_name          = "Crosshair",
    width                = 0,
    height               = 0,
    window_x             = 0,
    window_y             = 0,
    background_color_rgb = .[0,0,0],
    style                = WS_POPUP,
    style_ex             = WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TRANSPARENT
  );

  // make the black in the window trasnparent
  window_make_transparent_background(hwnd);

  // init Simp rendering stuff
  // we can't load simp texture before doing this
  // and we can't do this before creating a window
  Simp.set_render_target(hwnd);

  // load the correct crosshair image into a simp texture
  init_texture();


  { // we finally know the width and height of the crosshair png
    // base the width and height of the window on the dyanmically loaded image size, considering scale
    scale : float = cast(float)get_scale_from_cmd_or_exe_name() / cast(float)100;

    width  = xx (crosshair_texture.width  * scale);
    height = xx (crosshair_texture.height * scale);

    x := Monitor.size(hwnd).w/2 - width/2;
    y := Monitor.size(hwnd).h/2 - height/2;

    SetWindowPos(hwnd, HWND_TOP, xx x, xx y, xx width, xx height, 0);
    render(); // we do a quick render after setting the window size to refresh stuff
  }

  // main game loop
  while 1 {
    update();
    render(); // :render_once
    tfree();
    sleep_milliseconds(1000);
  }
}

get_scale_from_cmd_or_exe_name :: () -> int {
  // get scale from cmd argument
  scale := cmd_arg("scale");
  if scale != 0 return scale;

  // get scale from the exe name
  cmd0 := cmd_arg(0);
  scale_index := find_index_from_left(cmd0, "scale=");
  if scale_index != -1 {
    valstr := substr(cmd0, scale_index+"scale=".count);
    scale := parse_int(*valstr);
    if scale != 0 return scale;
  }

  return 100;
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
#import "String";

Simp :: #import "Simp";
