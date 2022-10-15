# Overview

Carl is a (at this point *very* simple) bot made for 3D / FPS games made in Godot. It's been my own project as an introduction to the engine, and I hope it will help others in their projects as well! It checks several things around it's surroundings, like objects in it's immediate proximity, field of view, or otherwise given objectives and influences a float value attached to a given behavior (Advance, attack, retreat, etc.) then behaves according to the behavior with the highest float value.

To use it in your own project, simply import the folder `Carl` into your project, then drag `Carl.tscn` into your level.
`Carl.gd` has a boolean labeled `debug`, which is set by default to false. Change this to true to get console messages while the game is running.

[A brief demonstration](https://www.youtube.com/watch?v=AAnUTsFay1M)

# Development Environment

Godot v3.5.1.stable

# Useful Websites

If you are new to Godot, and want to learn more about how Carl works, I suggest reading up on:
* [KinematicBody](https://docs.godotengine.org/en/stable/classes/class_kinematicbody.html?highlight=kinematicbody)
* [Vector3](https://docs.godotengine.org/en/stable/classes/class_vector3.html?highlight=Vector3)

# To-Do list:

* Make Carl follow enemies that leave it's FOV while focused on them.
* Impliment 'cover' behavior, which would send Carl looking for cover on taking a certain amount of damage.
* Add raycast check to FOV so Carl can't look through walls.
* Adding actual model and rigging/animations.
* Adding ability to interact with weapons.
