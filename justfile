set shell := ["cmd", "/c"]

clear := if os() == "windows" { "cls" } else { "clear" }

default:
    @just --list

build:
    zig build

test:
    {{clear}}
    zig build test_all

clean:
    if exist zig-out rmdir /s /q zig-out
    if exist .zig-cache rmdir /s /q .zig-cache

example name:
    {{clear}}
    zig build {{name}}
