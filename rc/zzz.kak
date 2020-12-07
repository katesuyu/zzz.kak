# SPDX-License-Identifier: 0BSD
# https://github.com/gruebite/zzz

# Detection
hook global BufCreate .*[.]zzz %{
    set-option buffer filetype zzz
}

# Initialization
hook global WinSetOption filetype=zzz %{
    require-module zzz

    hook window ModeChange pop:insert:.* -group zzz-trim-indent zzz-trim-indent
    hook window InsertChar \n -group zzz-indent zzz-indent-on-new-line
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window zzz-.+ }
}

hook -group zzz-highlight global WinSetOption filetype=zzz %{
    add-highlighter window/zzz ref zzz
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/zzz }
}


provide-module zzz %{

# Highlighters
add-highlighter shared/zzz            regions
add-highlighter shared/zzz/comment    region '#' '$' fill comment
add-highlighter shared/zzz/string     region '(?:^|[:,;]) *\K"' '$|"' regex '(".*"(?=:))|.+' 0:string 1:keyword
add-highlighter shared/zzz/literal    region '(?:^|[:,;]) *\K(?![ #"\[])' '$|(?=[#:,;])' group
add-highlighter shared/zzz/multiline  region -match-capture -recurse '\[(=*)\[' '\[(=*)\[' '\](=*)\] *' group

add-highlighter shared/zzz/literal/   regex '.+(?:$|(?=[#,;]))' 0:string
add-highlighter shared/zzz/literal/   regex '.+(?=:)' 0:keyword
add-highlighter shared/zzz/literal/   regex '\btrue|\bfalse|(?:\B[+-])?\b\d+(?:[.]\d*)*(?:[eE][+-]?\d*)?\b' 0:value
add-highlighter shared/zzz/multiline/ fill string
add-highlighter shared/zzz/multiline/ regex '.+(?=:)(?::\K)?' 0:keyword

# Commands
define-command -hidden zzz-trim-indent %{
    # remove trailing white spaces
    try %{ execute-keys -draft -itersel <a-x> s \h+$ <ret> d }
}

define-command -hidden zzz-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy '#' comment prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s ^\h*\K#\h* <ret> y gh j P }
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # filter previous line
        try %{ execute-keys -draft k : zzz-trim-indent <ret> }
        # indent after :
        try %{ execute-keys -draft <space> k x <a-k> :$ <ret> j <a-gt> }
    }
}

}
