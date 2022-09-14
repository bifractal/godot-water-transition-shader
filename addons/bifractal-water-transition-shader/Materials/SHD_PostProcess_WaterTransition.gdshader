// MIT License
// Copyright (c) 2022 BIFRACTAL - Florian Roth

shader_type canvas_item;

uniform vec4 water_line_color : hint_color = vec4(0.1f, 0.25f, 0.4f, 1.0f);
uniform vec4 underwater_color : hint_color = vec4(0.0f, 0.25f, 0.25f, 1.0f);
uniform float underwater_blur_lod : hint_range(0.0f, 5.0f, 1.0f) = 2.0f;

uniform sampler2D underwater_refraction_noise;

// Masks
uniform sampler2D water_transition_mask;

/**
 * Generate Water Line
 */
vec3 generate_water_line(vec2 screen_uv, float time,
						 float water_transition_value, float line_thickness,
						 inout float top_mask, inout float bottom_mask,
						 inout float line_mask, inout vec2 refracted_uv)
{
	float y = water_transition_value;
	
	float line_top = smoothstep(0.0f, line_thickness, y);
	float line_bottom = smoothstep(-line_thickness, 0.0f, -y);
	float line = line_top * line_bottom * 2.0f;
	
	top_mask = clamp(1.0f - line_top, 0.0f, 1.0f);
	bottom_mask = clamp(1.0f - line_bottom, 0.0f, 1.0f);
	line_mask = line;
	
	float line_refraction = line * 0.025f;
	refracted_uv = screen_uv * vec2(1.0f, 1.0f + line_refraction);
	
	return water_line_color.rgb * line;
}


/**
 * Fragment Shader
 */
void fragment()
{
	// --> Masks
	float water_transition_value = textureLod(water_transition_mask, SCREEN_UV, 0.0f).r;
	float water_surface_mask = ceil(water_transition_value);

	// --> Water Line
	float water_line_thickness = 0.24f;
	
	float top_mask;
	float bottom_mask;
	float line_mask;
	vec2 refracted_uv;
	
	vec3 water_line = generate_water_line(SCREEN_UV, TIME, water_transition_value, water_line_thickness,
										  top_mask, bottom_mask, line_mask, refracted_uv);
	
	// --> Final Color
	float underwater_refraction_time = TIME * 0.1f;
	float underwater_refraction_intensity = 0.04f;
	
	vec2 underwater_refraction_uv = refracted_uv;
	
	underwater_refraction_uv += vec2(
		0.0f,
		texture(underwater_refraction_noise, SCREEN_UV + underwater_refraction_time).r - 0.5f // Fix y-offset.
	) * underwater_refraction_intensity;
	
	vec4 screen_texture_over = textureLod(SCREEN_TEXTURE, refracted_uv, 0.0f);
	vec4 screen_texture_under = textureLod(SCREEN_TEXTURE, underwater_refraction_uv, underwater_blur_lod);
	
	vec3 overwater_color = screen_texture_over.rgb * pow(top_mask, 2.0f);
	
	vec3 color = screen_texture_under.rgb * bottom_mask;
	color *= pow(1.0f - water_line.r, 40.0f);
	color += water_line;
	color *= underwater_color.rgb * (bottom_mask * 2.0f);
	
	COLOR.rgb = overwater_color + color;
}
