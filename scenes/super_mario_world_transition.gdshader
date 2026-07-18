shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float progress_trans : hint_range(0.0, 1.0);
uniform vec4 transition_color : source_color;


void fragment() {
    float t = progress_trans * 3.0;
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = SCREEN_UV;
    float _Speed = 15.0;
    float res = floor(pow(t, 1.4) * _Speed) * 2.0 + 0.01;
    uv *= iResolution / res;
    uv = floor(uv);
    uv /= iResolution / res;
    uv += res * 0.002;
    vec4 texture_pixelada = texture(SCREEN_TEXTURE, uv);
    float fade_start = 1.0; 
    float fade_end = 2.0;  
    float mix_factor = smoothstep(fade_start, fade_end, t);
    COLOR = mix(texture_pixelada, transition_color, mix_factor);
}