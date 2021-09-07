#!/usr/bin/env k
host:-1_`x(("/usr/bin/env";"hostname";"-s");"")
home:`env[]`HOME
d:`j?{x,1:0}/""  / read to EOF: on a socket stdin (how Claude Code passes it) 0:0 returns after one read()
(c;cw;ws):d`cost`"context_window"`workspace
td:c`"total_duration_ms"
(api;cst):_ 0.5+100*((c`"total_api_duration_ms")%td;c`"total_cost_usd")
mins:_ td%60000
secs:-2#"00",$60!_ td%1000
cwd:ws`"current_dir"
cwd:$[home~(#home)#cwd;"~",(#home)_ cwd;cwd]
ad:#ws`"added_dirs"
hd:host,":",cwd
ctx:"ctx:",($_ cw`"remaining_percentage"),"%"
usd:"$",($_ cst%100),".",-2#"00",$100!cst
lc:"+",($_ c`"total_lines_added"),"/-",$_ c`"total_lines_removed"
dur:($mins),"m",secs,"s (api:",($api),"%)"
parts:(hd;$[ad>0;"+",($ad),"dir";""];ctx;usd;lc;dur)
e:`c$27
`0:e,"[97m",(" | "/parts@&0<#'parts),e,"[0m"
/ h:`env[]`HOME;c:((`j?,/0:3)`workspace)`"current_dir";`0:(-1_`x(("/usr/bin/env";"hostname");"")),":",$[h~(#h)#c;"~",(#h)_c;c]'
