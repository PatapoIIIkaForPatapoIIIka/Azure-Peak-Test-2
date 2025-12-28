/obj/item/tent_kit
	name = "tent kit"
	desc = "A bundle of canvas and poles for pitching a tent."
	icon = 'icons/obj/items.dmi'
	icon_state = "box"
	w_class = WEIGHT_CLASS_BULKY
	var/layout_type = /datum/tent_layout/basic
	var/tent_integrity_percent = 1
	var/using = FALSE

/obj/item/tent_kit/attack_self(mob/user)
	if(!user)
		return
	if(using)
		to_chat(user, span_warning("I'm already setting up a tent."))
		return
	if(!user.is_holding(src))
		to_chat(user, span_warning("I need to hold [src] to set it up."))
		return
	if(tent_integrity_percent < TENT_MIN_PLACEMENT_INTEGRITY)
		to_chat(user, span_warning("[src] is too damaged to set up. It needs repairs first."))
		return
	using = TRUE
	user.visible_message(span_notice("[user] starts setting up [src]."), span_notice("I start setting up [src]."))
	if(!do_after(user, TENT_BUILD_TIME, target = src))
		using = FALSE
		return
	if(!user.is_holding(src))
		to_chat(user, span_warning("I need to keep holding [src] to finish setting it up."))
		using = FALSE
		return
	if(!place_tent(user))
		using = FALSE
		return
	using = FALSE

/obj/item/tent_kit/proc/set_tent_integrity(percent)
	percent = clamp(percent, 0, 1)
	tent_integrity_percent = percent
	obj_integrity = max_integrity * tent_integrity_percent

// TODO: Integrate tent kit repairs with the sewing skill and existing crafting/repair systems.

/obj/item/tent_kit/basic
	name = "basic tent kit"
	layout_type = /datum/tent_layout/basic

/obj/item/tent_kit/premium
	name = "premium tent kit"
	layout_type = /datum/tent_layout/premium

/obj/item/tent_mod
	name = "tent modification"
	desc = "An enhancement for a tent controller."
	icon = 'icons/obj/items.dmi'
	icon_state = "circuit"
	w_class = WEIGHT_CLASS_SMALL

/obj/structure/tent_wall
	name = "tent wall"
	desc = "A taut canvas wall that blocks the elements."
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "woodenbarricade_r"
	anchored = TRUE
	density = TRUE
	opacity = FALSE
	max_integrity = 200
