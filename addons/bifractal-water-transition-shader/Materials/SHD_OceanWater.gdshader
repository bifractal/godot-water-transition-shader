// MIT License
// Copyright (c) 2022 BIFRACTAL - Florian Roth

shader_type spatial;
render_mode cull_disabled;

uniform vec3 dronePosition;

// General Settings
uniform float roughness 				: hint_range(0.0, 1.0)		= 0.03f;
uniform float metallic 					: hint_range(0.0, 1.0)		= 0.5f;
uniform float alphaEdgeFadeIntensity 	: hint_range(0.0, 1.0)		= 0.15f;
uniform float underWaterDepthExponent	: hint_range(0.0, 8.0)		= 0.5f;
uniform vec4 underWaterColor			: hint_color 				= vec4(0.0f, 0.25f, 0.25f, 1.0f);
uniform float uvScale 					: hint_range(0.0, 1000.0)	= 20.0f;

// Water Normal
uniform sampler2D waterNormal;
uniform float waterNormalScaleUV 		: hint_range(0.0, 100.0)	= 2.0f;
uniform float waterNormalTimeScale1 	: hint_range(0.0, 1.0) 		= 0.005f;
uniform float waterNormalTimeScale2  	: hint_range(0.0, 1.0)		= 0.0035f;

// Foam
uniform sampler2D foamTexture;
uniform float foamFadeSize 				: hint_range(0.0, 1.0) 		= 0.15f;
uniform vec4 foamColor 					: hint_color 				= vec4(0.18f, 0.18f, 0.18f, 1.0f);
uniform float foamNormalIntensity 		: hint_range(0.0, 1.0) 		= 0.4f;

// Vertex Stuff
varying vec2 uv;
varying vec4 position;
varying mat4 mvMatrix;

float linearize(float depth)
{
	depth = 2.0 * depth - 1.0;
	return 0.3f * 1000.0f / (1000.0f + depth * (0.3f - 1000.0f));
}

float calc_drone_wind_area(mat4 invCameraMatrix, vec3 vertexPosition, float size)
{
	vec3 dronePos = (invCameraMatrix * vec4(dronePosition, 1.0f)).xyz;
	vec3 droneArea = vec3(1.0f - smoothstep(0.4f, 1.0f, distance(dronePos, vertexPosition) * size));
	
	return length(droneArea);
}

void vertex()
{
	mat4 mvp = PROJECTION_MATRIX * MODELVIEW_MATRIX;

	uv = UV * uvScale;
	position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0f);
	mvMatrix = MODELVIEW_MATRIX;
}

void fragment()
{
	// Calculate Scene Depth
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0f - 1.0f;
	
	vec4 worldPos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	worldPos.xyz /= worldPos.w;
	
	float linearDepth = worldPos.z;
	
	float dist = pow(1.0f - worldPos.w, underWaterDepthExponent);
	float maxFoamNormalDist = 1.0f - clamp(distance(VIEW, position.xyz) * 0.004f, 0.0f, 1.0f);
	
	// Fades
	float foamFade = clamp(1.0 - smoothstep(linearDepth + foamFadeSize, linearDepth, VERTEX.z), 0.0f, 1.0f);
	float alphaEdgeFade = clamp(1.0 - smoothstep(linearDepth + alphaEdgeFadeIntensity, linearDepth, VERTEX.z), 0.0f, 1.0f);
	
	// Normal Texture
	vec4 normalTexture = texture(waterNormal, vec2(uv.x + TIME * waterNormalTimeScale1, uv.y) * waterNormalScaleUV);
	vec4 normalTexture2 = texture(waterNormal, vec2(uv.x, uv.y + TIME * waterNormalTimeScale2) * waterNormalScaleUV);

	// Screen Texture
	float screenTexUV_X = SCREEN_UV.x;
	float screenTexUV_Y = SCREEN_UV.y * 0.9f * (normalTexture2.y * 2.2f);
	vec2 screenTextureUV = vec2(screenTexUV_X, screenTexUV_Y);
	vec3 screenTexture = textureLod(SCREEN_TEXTURE, screenTextureUV, 1.2).rgb;

	// Water Color
	vec3 waterColor = ((1.0f - dist) * screenTexture);
	
	// Foam
	float foamRange = 1.0f - foamFade;
	float foamWaves = clamp(sin((foamFade * 6.0f) + TIME * 2.0f), 0.2f, 1.0f) * foamRange;
	
	vec2 foamTexUV = vec2(uv * 14.0f);
	foamTexUV.y += foamWaves * 0.02f;
	
	vec3 foamTex = texture(foamTexture, foamTexUV).rgb;
	vec3 foamTextureMix = foamColor.rgb * (foamTex.rgb);
	vec3 foamFinalColor = foamTextureMix * foamRange * foamWaves;
	
	// General
	ALPHA = alphaEdgeFade;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = 0.0f;
	
	// Clear Coat
	CLEARCOAT = 0.5f;
	CLEARCOAT_GLOSS = 1.0f;
	
	// Normal
	normalTexture.x += (foamWaves * foamNormalIntensity) * maxFoamNormalDist;
	NORMALMAP = mix(normalTexture.rgb, normalTexture2.rgb, 0.5f);

	// Albedo
	ALBEDO = waterColor + (underWaterColor.rgb * (1.0f - dist));
	
	EMISSION += foamFinalColor * 2.4f;
}
