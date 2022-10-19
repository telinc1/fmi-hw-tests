#!/bin/bash

[ -z "$1" ] && exit 1

# dir names in the tests repo must match expected file names of the tasks
# e.g. "$tests$/1" contains the tests for "$homework$/1.cpp"

test_dir=$1

mkdir test-results || exit 1

# breaks horribly if a task or test name has a space in it
# luckily, we control both of those

errors=0

for task in $(find "$test_dir" -mindepth 1 -maxdepth 1 -not -name '.*' -type d -printf '%f\n' | sort); do
    results="test-results/$task.txt"

    echo -n "Tests ran on: " >> $results
    date >> $results
    echo >> $results

    echo "Compiler output:" >> $results
    g++ "$task.cpp" -o "$task.out" -std=c++14 -Wpedantic &>> $results

    if [ $? -eq 0 ]; then
        echo >> $results
        echo "Compilation OK." >> $results
        echo >> $results
        echo >> $results

        for test in $(find "$test_dir/$task" -mindepth 1 -maxdepth 1 -not -name '.*' -type d -printf '%f\n' | sort); do
            timeout 3 "./$task.out" < "$test_dir/$task/$test/in" &> "$test_dir/$task/$test/actual"

            echo "Test: $test" >> $results
            echo "------" >> $results

            echo "Input:" >> $results
            cat "$test_dir/$task/$test/in" >> $results
            echo >> $results

            echo "Expected:" >> $results
            cat "$test_dir/$task/$test/out" >> $results
            echo >> $results

            echo "Actual:" >> $results
            cat "$test_dir/$task/$test/actual" >> $results
            echo >> $results

            if diff -Z "$test_dir/$task/$test/actual" "$test_dir/$task/$test/out" > /dev/null; then
                echo "OK" >> $results
            else
                echo "Failed" >> $results
                errors=$((errors+1))
            fi

            echo >> $results
            echo >> $results
        done
    else
        errors=$((errors+1))

        echo >> $results
        echo "Compilation failed. Skipping tests." >> $results
    fi
done

exit $errors
