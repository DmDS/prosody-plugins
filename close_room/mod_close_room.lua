local LOGLEVEL = "debug"
local MIN = module:get_option_number("conference_timeout", 10)
local TIMEOUT = MIN
local is_healthcheck_room = module:require "util".is_healthcheck_room
local st = require "util.stanza"
local timer = require "util.timer"
module:log(LOGLEVEL, "loaded")

module:hook("muc-occupant-left", function (event)
    local room = event.room
    local mods = room:each_affiliation("owner");
    local leaver = event.occupant.bare_jid;
    local a = 0;
    local b = 0;

    for mod in mods do
        a = a + 1;
        if mod == leaver then
            room:set_affiliation(true, leaver, "outcast");
            module:log("info", "still a moderator present");
            a = a - 1;
        end
    end

    for mod in mods do

        module:log("info", "mods: %s", a);

        if a == 1 then
	    if is_healthcheck_room(room.jid) then
	        module:log(LOGLEVEL, "skip restriction")
	        return
	    end

	    room:broadcast_message(
	         st.message({ type="groupchat", from=room.jid })
	         :tag("subject")
	         :text("The conference will end in "..MIN.." sec"):up())

	    module:log(LOGLEVEL, "set timeout for conference, %s secs, %s",
	                         TIMEOUT, room.jid)

	    timer.add_task(TIMEOUT, function()
	        if is_healthcheck_room(room.jid) then
	            return
	        end

	        for mod in mods do
	            b = b + 1;
	        end

		if b == 1 then
	           for _, p in room:each_occupant() do
                       room:broadcast_message(
                           st.message({ type="groupchat", from=room.jid })
                           :tag("subject")
                           :text("THE CONFERENCE IS OVER"):up())

	               room:set_affiliation(true, p.jid, "outcast")
   	               module:log("info", "kick the occupant, %s", p.jid)
   	               module:log("info", "the conference terminated")
	           end
		else
                   module:log("info", "still a moderator present");
                   room:broadcast_message(
                     st.message({ type="groupchat", from=room.jid })
                     :tag("subject")
                     :text(roomName))
		end
    	    end)
        end
    end
end)
