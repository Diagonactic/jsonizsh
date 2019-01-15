#!/usr/bin/env -S jq -rf
def filtered(byrules): ..|select(byrules);
def prim_locs:  path(filtered(type!="array" and type!="object"));
def array_locs: path(filtered(type=="array"));

{
    keys: (
        [prim_locs | join(".")] + [array_locs | join(".") + ".length"]
    ),
    vals:(
        [getpath(prim_locs) | tostring] + [getpath(array_locs) | length | tostring]
    )
} | ([.keys, .vals] | transpose)[][]
