/datum/tent_element_state
	var/expected_type
	var/expected_max_integrity
	var/is_turf = FALSE
	var/turf/placed_turf
	var/obj/placed_obj
	var/original_turf_type

/datum/tent_element_state/proc/current_integrity()
	if(is_turf)
		if(placed_turf && !QDELETED(placed_turf) && placed_turf.type == expected_type)
			return placed_turf.turf_integrity
		return 0
	if(placed_obj && !QDELETED(placed_obj) && placed_obj.type == expected_type)
		return placed_obj.obj_integrity
	return 0

/obj/structure/tent_controller
	name = "tent controller"
	desc = "A central knot of ropes and canvas that keeps the tent together."
	icon = 'icons/obj/items.dmi'
	icon_state = "stock_parts"
	density = FALSE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	obj_flags = CAN_BE_HIT | USES_TGUI
	var/mob/living/owner
	var/kit_type
	var/datum/tent_layout/layout
	var/list/tent_turfs
	var/list/element_states
	var/list/mod_slots
	var/packing = FALSE

/obj/structure/tent_controller/Initialize(mapload)
	. = ..()
	element_states = list()
	tent_turfs = list()
	mod_slots = list()

/obj/structure/tent_controller/ui_interact(mob/user, datum/tgui/ui)
	if(!user)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TentController", "Tent Controller")
		ui.open()

/obj/structure/tent_controller/ui_data(mob/user)
	var/list/data = ..()
	data["owner_name"] = owner ? owner.real_name : "Unknown"
	data["is_owner"] = (user == owner)
	data["pack_time"] = (user == owner) ? TENT_PACK_TIME_OWNER : TENT_PACK_TIME_OTHER
	data["can_pack"] = can_pack(user, silent = TRUE)
	return data

/obj/structure/tent_controller/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(action == "pack")
		attempt_pack(ui.user)
		return TRUE
	return FALSE

/obj/structure/tent_controller/attack_hand(mob/user)
	if(!SStgui)
		return fallback_pack_prompt(user)
	return ..()

/obj/structure/tent_controller/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/tent_mod))
		if(mod_slots.len >= TENT_DEFAULT_MOD_SLOTS)
			to_chat(user, span_warning("There is no free slot to install [I]."))
			return TRUE
		user.visible_message(span_notice("[user] installs [I] into [src]."), span_notice("I install [I] into [src]."))
		I.forceMove(src)
		mod_slots += I
		return TRUE
	return ..()

/obj/structure/tent_controller/proc/fallback_pack_prompt(mob/user)
	if(!user)
		return FALSE
	var/answer = alert(user, "Pack up this tent?", "Tent Controller", "Pack", "Cancel")
	if(answer != "Pack")
		return FALSE
	attempt_pack(user)
	return TRUE

/obj/structure/tent_controller/proc/can_pack(mob/user, silent = FALSE)
	if(!user || QDELETED(src))
		return FALSE
	if(!Adjacent(user))
		if(!silent)
			to_chat(user, span_warning("I need to be closer to the controller."))
		return FALSE
	if(!tent_turfs.len)
		return TRUE
	for(var/turf/T as anything in tent_turfs)
		for(var/mob/living/L in T)
			if(L.stat != DEAD)
				if(!silent)
					to_chat(user, span_warning("Someone is still inside the tent."))
					return FALSE
	return TRUE

/obj/structure/tent_controller/proc/attempt_pack(mob/user)
	if(packing)
		return
	if(!can_pack(user))
		return
	packing = TRUE
	var/pack_time = (user == owner) ? TENT_PACK_TIME_OWNER : TENT_PACK_TIME_OTHER
	user.visible_message(span_notice("[user] starts packing up [src]."), span_notice("I start packing up [src]."))
	if(!do_after(user, pack_time, target = src))
		packing = FALSE
		return
	if(!can_pack(user))
		packing = FALSE
		return
	pack_tent(user)
	packing = FALSE

/obj/structure/tent_controller/proc/pack_tent(mob/user)
	var/turf/drop_turf = get_turf(src)
	var/obj/item/tent_kit/new_kit = new kit_type(drop_turf)
	var/percent = calculate_integrity_percent()
	new_kit.set_tent_integrity(percent)
	for(var/datum/tent_element_state/state as anything in element_states)
		if(state.is_turf)
			if(state.placed_turf && !QDELETED(state.placed_turf) && state.original_turf_type)
				state.placed_turf.ChangeTurf(state.original_turf_type, flags = CHANGETURF_IGNORE_AIR)
			continue
		if(state.placed_obj && !QDELETED(state.placed_obj))
			qdel(state.placed_obj)
	for(var/obj/item/tent_mod/mod as anything in mod_slots)
		if(!QDELETED(mod))
			mod.forceMove(drop_turf)
	qdel(src)

/obj/structure/tent_controller/proc/calculate_integrity_percent()
	if(!layout || layout.expected_max_integrity <= 0)
		return 1
	var/current_integrity = 0
	for(var/datum/tent_element_state/state as anything in element_states)
		current_integrity += state.current_integrity()
	return clamp(current_integrity / layout.expected_max_integrity, 0, 1)
