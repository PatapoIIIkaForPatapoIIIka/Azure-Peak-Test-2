/datum/tent_world_cell
	var/datum/tent_layout_cell/layout_cell
	var/turf/target_turf

/obj/item/tent_kit/proc/place_tent(mob/user)
	var/datum/tent_layout/layout = new layout_type
	var/turf/origin = get_step(user, user.dir)
	if(!origin)
		to_chat(user, span_warning("There is no space to set up a tent."))
		return FALSE
	var/list/world_cells = build_world_cells(layout, origin, user.dir)
	if(!world_cells)
		to_chat(user, span_warning("The tent cannot fit there."))
		return FALSE
	var/list/tent_turfs = collect_footprint_turfs(world_cells)
	if(!can_place_tent(user, world_cells))
		return FALSE
	var/turf/door_turf = get_door_turf(world_cells)
	if(!door_turf)
		to_chat(user, span_warning("The tent layout is missing a door."))
		return FALSE
	var/turf/controller_turf = find_controller_turf(door_turf, user.dir, tent_turfs)
	if(!controller_turf)
		to_chat(user, span_warning("There is no room to place the tent controller."))
		return FALSE
	var/obj/structure/tent_controller/controller = new(controller_turf)
	controller.owner = user
	controller.kit_type = type
	controller.layout = layout
	controller.tent_turfs = tent_turfs
	controller.element_states = list()
	place_layout_elements(controller, world_cells, user.dir)
	qdel(src)
	return TRUE

/obj/item/tent_kit/proc/build_world_cells(datum/tent_layout/layout, turf/origin, dir)
	var/list/world_cells = list()
	for(var/datum/tent_layout_cell/cell as anything in layout.cells)
		var/list/offset = rotate_tent_offset(cell.dx, cell.dy, dir)
		var/target_x = origin.x + offset[1]
		var/target_y = origin.y + offset[2]
		var/turf/target = locate(target_x, target_y, origin.z)
		if(!target)
			return null
		var/datum/tent_world_cell/world_cell = new
		world_cell.layout_cell = cell
		world_cell.target_turf = target
		world_cells += world_cell
	return world_cells

/obj/item/tent_kit/proc/collect_footprint_turfs(list/world_cells)
	var/list/tent_turfs = list()
	for(var/datum/tent_world_cell/world_cell as anything in world_cells)
		if(world_cell.layout_cell.is_footprint)
			tent_turfs += world_cell.target_turf
	return tent_turfs

/obj/item/tent_kit/proc/can_place_tent(mob/user, list/world_cells)
	for(var/datum/tent_world_cell/world_cell as anything in world_cells)
		if(!world_cell.layout_cell.is_footprint)
			continue
		var/turf/T = world_cell.target_turf
		if(T.density)
			to_chat(user, span_warning("The ground is blocked at [T]."))
			return FALSE
		for(var/atom/movable/A in T)
			to_chat(user, span_warning("[A] is in the way of the tent."))
			return FALSE
		if(!overhead_is_clear(user, T))
			return FALSE
	return TRUE

/obj/item/tent_kit/proc/overhead_is_clear(mob/user, turf/T)
	var/turf/above = GET_TURF_ABOVE(T)
	if(!above)
		return TRUE
	if(above.density)
		return TRUE
	for(var/atom/movable/A in above)
		to_chat(user, span_warning("[A] above blocks the tent from being raised."))
		return FALSE
	return TRUE

/obj/item/tent_kit/proc/get_door_turf(list/world_cells)
	for(var/datum/tent_world_cell/world_cell as anything in world_cells)
		if(world_cell.layout_cell.is_door)
			return world_cell.target_turf
	return null

/obj/item/tent_kit/proc/find_controller_turf(turf/door_turf, dir, list/tent_turfs)
	var/list/side_dirs = list(turn(dir, 90), turn(dir, -90))
	for(var/side_dir in side_dirs)
		var/turf/candidate = get_step(door_turf, side_dir)
		if(!candidate || (candidate in tent_turfs))
			continue
		if(candidate.density)
			continue
		var/blocked = FALSE
		for(var/atom/movable/A in candidate)
			blocked = TRUE
			break
		if(blocked)
			continue
		return candidate
	return null

/obj/item/tent_kit/proc/place_layout_elements(obj/structure/tent_controller/controller, list/world_cells, dir)
	for(var/datum/tent_world_cell/world_cell as anything in world_cells)
		var/datum/tent_layout_cell/cell = world_cell.layout_cell
		var/turf/target = world_cell.target_turf
		if(cell.turf_type)
			var/original_type = target.type
			var/turf/new_turf = target.ChangeTurf(cell.turf_type, flags = CHANGETURF_IGNORE_AIR)
			var/datum/tent_element_state/turf_state = new
			turf_state.is_turf = TRUE
			turf_state.placed_turf = new_turf
			turf_state.expected_type = cell.turf_type
			var/turf/expected_turf = cell.turf_type
			turf_state.expected_max_integrity = initial(expected_turf.max_integrity)
			turf_state.original_turf_type = original_type
			controller.element_states += turf_state
		if(cell.obj_type)
			var/obj/new_obj = new cell.obj_type(target)
			if(cell.is_door)
				new_obj.dir = dir
			var/datum/tent_element_state/obj_state = new
			obj_state.is_turf = FALSE
			obj_state.placed_obj = new_obj
			obj_state.expected_type = cell.obj_type
			var/obj/expected_obj = cell.obj_type
			obj_state.expected_max_integrity = initial(expected_obj.max_integrity)
			controller.element_states += obj_state
	return

/obj/item/tent_kit/proc/rotate_tent_offset(dx, dy, dir)
	switch(dir)
		if(NORTH)
			return list(dx, dy)
		if(EAST)
			return list(dy, -dx)
		if(SOUTH)
			return list(-dx, -dy)
		if(WEST)
			return list(-dy, dx)
	return list(dx, dy)
