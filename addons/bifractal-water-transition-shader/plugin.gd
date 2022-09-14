# MIT License
# Copyright (c) 2022 BIFRACTAL - Florian Roth

tool
extends EditorPlugin

const CUSTOM_TYPE_NAME		= "WaterTransitionShader"
const CUSTOM_TYPE_SCRIPT	= preload("WaterTransitionShader.gd")
const CUSTOM_TYPE_ICON		= preload("Icons/icon.png")

# Enter Tree
func _enter_tree():
	add_custom_type(CUSTOM_TYPE_NAME, "Spatial", CUSTOM_TYPE_SCRIPT, CUSTOM_TYPE_ICON)

# Exit Tree
func _exit_tree():
	remove_custom_type(CUSTOM_TYPE_NAME)
