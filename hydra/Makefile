# Copyright 2023-present Cornell University and Stanford University
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

NAME=tpc

.PHONY: all build doc run install test clean

all: build

build:
	dune build && echo

doc:
	dune build @doc

deps:
	opam install . --deps-only

run: build
	dune exec -- $(NAME)

install: build
	dune install

test: build
	cd test && dune exec -- ./test.exe

clean:
	dune clean
