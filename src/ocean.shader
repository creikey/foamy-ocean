shader_type spatial;
//render_mode diffuse_toon;

// direction.x, direction.y, steepness, wavelength
uniform vec4 wave_1 = vec4(0.14, 0.29, 0.25, 18.93);
uniform vec4 wave_2 = vec4(0.3, 0.35, 0.28, 12.0);
uniform vec4 wave_3 = vec4(0.8, 3.18, 0.22, 9.0);

uniform float noise_zoom = 0.22;
uniform float noise_amp = 9.59;

uniform vec4 color: hint_color = vec4(0.3411, 0.5333, 0.6627, 1.0);
uniform float color_mid_height = 3.0;
uniform float foam_level = 5.64;
uniform sampler2D foam_texture;
uniform float foam_scale = 114.32;
uniform float foam_height = 6.61;
//uniform float refraction = 0.05;
uniform float metallic = 0.59;
uniform float roughness = 0;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16,16);
uniform float normal_zoom = 1.0;
uniform float normal_flow_divisor = 350.0;

uniform float PI = 3.14159;

float hash(vec2 p) {
  return fract(sin(dot(p * 17.17, vec2(14.91, 67.31))) * 4791.9511);
}

float noise(vec2 x) {
  vec2 p = floor(x);
  vec2 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  vec2 a = vec2(1.0, 0.0);
  return mix(mix(hash(p + a.yy), hash(p + a.xy), f.x),
         mix(hash(p + a.yx), hash(p + a.xx), f.x), f.y);
}

float fbm(vec2 x) {
  float height = 0.0;
  float amplitude = 0.5;
  float frequency = 3.0;
  for (int i = 0; i < 6; i++){
    height += noise(x * frequency) * amplitude;
    amplitude *= 0.5;
    frequency *= 2.0;
  }
  return height;
}

vec3 gernster_wave(vec4 params, vec2 pos, float time) {
	float steepness = params.z;
	float wavelength = params.w;
	float k = 2.0 * PI / wavelength;
	float c = sqrt(9.81 / k);
	vec2 d = normalize(params.xy);
	float f = k * (dot(d, pos.xy) - c * time);
	float a = steepness / k;
	return vec3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f)));
}

vec3 wave(vec2 pos, float time) {
	vec3 to_return = vec3(0.0);
	to_return += gernster_wave(wave_1, pos, time);
	to_return += gernster_wave(wave_2, pos, time);
	to_return += gernster_wave(wave_3, pos, time);
	to_return.y += fbm(pos.xy * (noise_zoom/10.0)) * noise_amp;
	return to_return;
}

varying float height;

void vertex() {
	float time = TIME / 1.5;
	vec3 wave_result = wave(VERTEX.xz, time);
	VERTEX.y += wave_result.y;
	height = wave_result.y;
	VERTEX.x += wave_result.x;
	VERTEX.z += wave_result.z;
	TANGENT = normalize(vec3(0.0, wave(VERTEX.xz + vec2(0.0, 0.2), time).y - wave(VERTEX.xz + vec2(0.0, -0.2), time).y, 0.4));
	BINORMAL = normalize(vec3(0.4, wave(VERTEX.xz + vec2(0.2, 0.0), time).y - wave(VERTEX.xz + vec2(-0.2, 0.0), time ).y, 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}

void fragment() {
	// calculate depth for foam
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	depth = depth * 2.0 - 1.0;
	depth = PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
	depth = depth + VERTEX.z;
	// calculate foam mask stuff
	float foam_scroll = TIME/4.0;
	vec2 scaled_uv = UV * foam_scale; 
	float channelA = texture(foam_texture, scaled_uv - vec2(foam_scroll, cos(UV.x))).r; 
	float channelB = texture(foam_texture, scaled_uv * 0.5 + vec2(sin(UV.y), foam_scroll)).b;
	float mask = (channelA + channelB) * 0.95;
	mask = pow(mask, 2);
	mask = clamp(mask, 0, 1);
	ALBEDO = color.rgb * ((height + color_mid_height) / 5.0);
	if(height > foam_height) {
		EMISSION = vec3(1.0 - mask) * pow(height - foam_height, 1.0);
	}
	if(depth < foam_level) {
		EMISSION = vec3(1.0 - mask) * pow((foam_level - depth)/foam_level, 2.0);
	}
	ALPHA = color.a;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMALMAP = texture(texture_normal,(UV + TIME/normal_flow_divisor)*normal_zoom).rgb;
	NORMALMAP_DEPTH = normal_scale;
}