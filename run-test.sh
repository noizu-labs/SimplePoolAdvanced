#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

MIX_ENV=test elixir --name first@127.0.0.1 --cookie apple -S mix test


