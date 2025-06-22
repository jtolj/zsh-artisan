#--------------------------------------------------------------------------
# Laravel artisan plugin for zsh
#--------------------------------------------------------------------------
#
# This plugin adds an `artisan` shell command that will find and execute
# Laravel's artisan command from anywhere within the project. It also
# adds shell completions that work anywhere artisan can be located.

function artisan() {
    local artisan_path=`_artisan_find`

    if [ "$artisan_path" = "" ]; then
        >&2 echo "zsh-artisan: artisan not found. Are you in a Laravel directory?"
        return 1
    fi

    local laravel_path=`dirname $artisan_path`
    local artisan_cmd


    # Allow adding a prefix for valet and multiple PHP versions
    if [ -n "$ARTISAN_PREFIX" ]; then
        artisan_cmd="$ARTISAN_PREFIX php artisan"
    else
        artisan_cmd="php artisan"
    fi
    
    local artisan_start_time=`date +%s`

    cd $artisan_path
    eval $artisan_cmd $*
    cd - > /dev/null

    local artisan_exit_status=$? # Store the exit status so we can return it later

    if [[ $1 = "make:"* && $ARTISAN_OPEN_ON_MAKE_EDITOR != "" ]]; then
        # Find and open files created by artisan
        find \
            "$laravel_path/app" \
            "$laravel_path/tests" \
            "$laravel_path/database" \
            -type f \
            -newermt "-$((`date +%s` - $artisan_start_time + 1)) seconds" \
            -exec $ARTISAN_OPEN_ON_MAKE_EDITOR {} \; 2>/dev/null
    fi

    return $artisan_exit_status
}

compdef _artisan_add_completion artisan

function _artisan_find() {
    # Look for artisan up the file tree until the root directory
    local dir=.
    until [ $dir -ef / ]; do
        if [ -f "$dir/artisan" ]; then
            echo "$dir/"
            return 0
        fi

        dir+=/..
    done

    return 1
}

function _artisan_add_completion() {
    if [ "`_artisan_find`" != "" ]; then
        compadd `_artisan_get_command_list`
    fi
}

function _artisan_get_command_list() {
    artisan --raw --no-ansi list | sed "s/[[:space:]].*//g"
}
