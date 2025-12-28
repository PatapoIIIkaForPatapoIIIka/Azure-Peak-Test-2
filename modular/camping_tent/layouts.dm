/datum/tent_layout_cell
	var/dx
	var/dy
	var/is_door = FALSE
	var/is_footprint = TRUE
	var/turf_type
	var/obj_type

/datum/tent_layout
	var/name = "tent layout"
	var/list/cells
	var/expected_max_integrity = 0

/datum/tent_layout/New()
	. = ..()
	cells = list()
	build_cells()
	expected_max_integrity = calculate_expected_max_integrity()

/datum/tent_layout/proc/build_cells()
	return

/datum/tent_layout/proc/add_cell(dx, dy, turf_type = null, obj_type = null, is_door = FALSE, is_footprint = TRUE)
	var/datum/tent_layout_cell/cell = new
	cell.dx = dx
	cell.dy = dy
	cell.turf_type = turf_type
	cell.obj_type = obj_type
	cell.is_door = is_door
	cell.is_footprint = is_footprint
	cells += cell
	return cell

/datum/tent_layout/proc/calculate_expected_max_integrity()
	var/total_integrity = 0
	for(var/datum/tent_layout_cell/cell as anything in cells)
		if(cell.turf_type)
			var/turf/turf_type = cell.turf_type
			total_integrity += initial(turf_type.max_integrity)
		if(cell.obj_type)
			var/obj/obj_type = cell.obj_type
			total_integrity += initial(obj_type.max_integrity)
	return total_integrity

/datum/tent_layout/proc/get_door_cell()
	for(var/datum/tent_layout_cell/cell as anything in cells)
		if(cell.is_door)
			return cell
	return null

/datum/tent_layout/basic
	name = "basic tent"

/datum/tent_layout/basic/build_cells()
	for(var/x in -1 to 1)
		for(var/y in 0 to 2)
			var/is_border = (x == -1 || x == 1 || y == 0 || y == 2)
			if(x == 0 && y == 0)
				add_cell(x, y, obj_type = /obj/structure/mineral_door/wood, is_door = TRUE)
				continue
			if(is_border)
				add_cell(x, y, obj_type = /obj/structure/tent_wall)
			else
				add_cell(x, y)

/datum/tent_layout/premium
	name = "premium tent"

/datum/tent_layout/premium/build_cells()
	for(var/x in -2 to 2)
		for(var/y in 0 to 3)
			var/is_border = (x == -2 || x == 2 || y == 0 || y == 3)
			if(x == 0 && y == 0)
				add_cell(x, y, obj_type = /obj/structure/mineral_door/wood, is_door = TRUE)
				continue
			if(is_border)
				add_cell(x, y, obj_type = /obj/structure/tent_wall)
			else
				add_cell(x, y)
