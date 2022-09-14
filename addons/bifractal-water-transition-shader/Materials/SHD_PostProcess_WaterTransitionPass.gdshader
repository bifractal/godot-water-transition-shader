// MIT License
// Copyright (c) 2022 BIFRACTAL - Florian Roth

shader_type spatial;
render_mode unshaded;

uniform float water_level;
uniform float camera_near;
uniform vec3 camera_position;
uniform vec3 camera_direction_vector;

/**
 * Fragment Shader
 */
void fragment()
{
	// --> Clip Plane
	vec3 camera_vector = (vec4(VIEW, 1.0f) * INV_CAMERA_MATRIX).xyz;
	float cv_dot_cdv = dot(camera_vector, camera_direction_vector);
	vec3 cv_clip = camera_vector * (camera_near / cv_dot_cdv) + (camera_position - vec3(0.0f, water_level, 0.0f));
	
	// --> Fake Waves
	float line_time = TIME * 2.5f;
	float line_wave_freq = 8.0f;
	float line_wave_amp = 0.003f;
	float line_wave_offset = sin(line_time + SCREEN_UV.x * line_wave_freq) * line_wave_amp;
	
	// TODO Include camera rotation for additional wave offset.
	
	float y_offset = -cv_clip.y + 0.022f + line_wave_offset;

	ALBEDO = vec3(y_offset, 0.0f, 0.0f);
}
