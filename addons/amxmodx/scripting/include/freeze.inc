#if defined _freeze_included
    #endinput
#endif

#define _freeze_included

/*
@id			player's index to freeze
@bIsForSet		true if you want to freeze, false if not
@iType			Totally freeze/only speed
*/
native set_user_freeze(id, bool:bIsForSet, iType = 1)

/*
@id			player's index to check freeze
*/
native get_user_freeze(id)