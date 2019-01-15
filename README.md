# Jsonizsh - Consume JSON in ZSH - Version 0.1

Jsonizsh's goal is to make consuming JSON with ZSH convenient, safe and as reasonably performant (for shell scripts).  It started as a script for parsing output from `ffprobe -print_format json` without needing anything beyond the shell that is my default and morphed into a more general purpose tool for consuming JSON data in `zsh`.

I've used it, as seen below, for parsing all manner of AWS data, as well as GitHub.

## Project State

The state of the `zsh` script side is nowhere near feature complete, but it should work and it's working for me day-to-day for parsing JSON on my media server and various work projects.

The `jq` script, coupled with a function as described below, is quite solid -- I've thrown a lot at is currently alpha.  I'm using built-in methods for escaping and I'm fairly certain I'm doing things correctly, but it's easy to screw up.  The good news is that you can skip `zsh` entirely and write your own code to handle that if you wish. See *_Skipping the `jsonizsh` script_*, below.

## Using `jsonizsh`

### Requirements

Most of the heavy lifting is done by `jq`.  I don't believe I'm using any functions that wouldn't work on stable released, recent versions.

You'll also probably need a later version of `zsh`, and that'll likely get worse.  I run `zsh` 5.5.1-latest and only test on those.  I won't keep the script from running on older versions unless someone finds a specific compatibility issue.  That's also how any filed issues will be handled for specific `zsh` versions, however, I will happily accept any pull request that improves compatibility.

The state of the script -- at the time that I wrote this paragraph -- is really simple, so it'll likely fare well in backwards compatibility, but I have a few features I plan to add that could affect that.

Luckily, if the `zsh` version is a problem, but you can get the right `jq` version sorted out, you can write your own, simple, function to consume the output of the `jq` script in a way that works in the version of `zsh` that you're stuck with.  Continue reading for details.

### Basic Usage

Lets say we have a piece of JSON from AWS that looks like this:

```js
{
    "clusters": [
        {
            "clusterArn": "arn:aws:ecs:us-east-2:123456789:cluster/project-ocean",
            "clusterName": "project-ocean",
            "status": "ACTIVE",
            "registeredContainerInstancesCount": 1,
            "runningTasksCount": 1,
            "pendingTasksCount": 0,
            "activeServicesCount": 0,
            "statistics": [],
            "tags": []
        }
    ],
    "failures": []
}
```

To consume it, we'd simply call the script (assuming it's in path, the below will work)

```sh
declare -gA my_json_assoc    # No need to init; if the values are empty, the script sets empty
eval "$(jsonizsh myjson.json my_json_assoc)"
```

Here's what the `jsonizsh myjson.json my_json_assoc` produced:

```sh
# I was annoyed reading the output, so it really lines them up like that.
typeset -gA foo=(
    clusters.0.clusterArn                         arn:aws:ecs:us-east-2:123456789:cluster/project-ocean
    clusters.0.clusterName                        project-ocean
    clusters.0.status                             ACTIVE
    clusters.0.registeredContainerInstancesCount  1
    clusters.0.runningTasksCount                  1
    clusters.0.pendingTasksCount                  0
    clusters.0.activeServicesCount                0
    clusters.length                               1
    clusters.0.statistics.length                  0
    clusters.0.tags.length                        0
    failures.length                               0
)
typeset -ga foo_arrays=(
    clusters
    clusters.0.statistics
    clusters.0.tags
    failures
)

```

Each array (object or otherwise) includes a `.length` component in the association generated since this is almost always needed, is trivial to have `jq` spit out when parsing and looked like a reasonable way to sort out empty arrays at the same time.  That's my excuse if "because I needed it for everything that I needed this script for" isn't a satisfying enough explanation. :)

I recommend testing calls to determine what comes back by simply running the command, above.  For convenience, the script automatically aligns the fields/values, as seen above, to make it easy to read while reviewing and ... at least for me ... when I'm writing in `zsh`, I find it easier to analyse data I'm going to consume in the way I'd write it in `zsh` rather than the originating JSON.  But that's me.

I thought about flagging this feature out -- I'm not using `column`, but rather a `zsh` expansion to detect max column length.  This expansion is pretty cheap in my experience.  It falls over on large assocations, which could happen with JSON, but then ... associations fall over when they get too large, in general, so this isn't really suited for parsing huge JSON files.

You access the pieces/parts using association parameter expansion and various other tricks:

### Skipping the `jsonizsh` script

This is the answer to the question: But I use (bash|tsch|korn|whatever-the-shell), can I use this?

The answer is ... if it supports associations and can read files, you can, with a little extra work.

If it doesn't support associations, you probably still can, but there's probably something better out there for that problem.

All of the heavy lifting is done by the `tozsh.jq` script.  This script parses the JSON using `jq` and returns the results in the format:

```
flattened.non.array.name
value
... and on and on ...
flattened.array.name.length
array-length-value
```

These values can be directly consumed in `zsh`, or any other language it makes sense to do something like this in.

For `zsh`, specifically, you can rely on `zsh` to parse the values safely with the following function if using the included script isn't desired for whatever reason:


```sh
function json_to_zsh() {
    # Make sure we have a parameter and that it points to a fileish thing that exists
    if (( $# != 1 ));   then print "$0: Invalid usage - Expected a json-file" > /dev/stderr; return 1; fi
    if [[ ! -e "$1" ]]; then print "$0: The path provided, '$1', was not found"; fi
    typeset -i RC=0
    typeset -a ar_result=( "${(f@)$("/path/to/tozsh.jq" "$1")}" )

    # Exit if we get nothing back or if the length is not even, indicating that `jq` failed
    if [[ -z "$ar_result" ]] || (( ${#ar_result[@]} % 2 != 0 )); then
        declare -gA get_json_result=( ); return 1
    fi

    declare -gA get_json_result=( "${ar_result[@]}" )
}
```

I haven't tested the above, but it looks like a start.  The above function takes a json file as a parameter and sets a global association variable named `get_json_result` to the values returned by the `jq` script described above.

## What's the Name all About?

Its name is borne out of the original desire to write a JSON parser with no dependencies outside of ZSH (specific minimum versions).  The trade-off was time/complexity of the ZSH script vs. taking a dependency on a tool (`jq`) that isn't installed by default on many distributions/configurations (but is available in an acceptable version in most repos).

Since it's not pure ZSH and it felt like an awful name on the surface, I went with Jsonizsh, as in, Json ... in zsh ... ish.  I pronounce it "Jsonish" but it's a pretty silly, simple, project so you can call it Tennis if you want.
