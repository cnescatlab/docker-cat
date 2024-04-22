# Test documentation

## List of scripted integration tests

1. Up
   - function: tests_up
   - purpose: test if the SonarQube server is UP
1. Quality Gate check
   - function: tests_check_qg
   - purpose: check that the CNES Quality Gate is available on the server and is set as default
1. Quality Profiles check
   - function: tests_check_qp
   - purpose: check that all CNES Quality Profiles are available on the server
1. Java
   - function: test_language_java
   - purpose: Check that the Java language is supported and that the right plugins are executed.
1. Shell
   - function: test_language_shell
   - purpose: Check that the Shell language is supported and that the right plugins are executed.
1. ShellCheck
   - function: test_tool_shellcheck
   - purpose: Check that ShellCheck can be launched from within the container to analyze scripts in the project.
1. Fortran
   - functions: test_language_fortran_77 and test_language_fortran_90
   - purpose: Check that the Fortran 77 and 90 languages are supported and that the right plugins are executed.
1. Python
   - function: test_language_python
   - purpose: Check that the Python language is supported and that CNES Quality Profiles are usable.
1. Pylint
   - function: test_tool_pylint
   - purpose: Check that Pylint can be launched from within the container to analyze Python projects.
1. Import pylint results in SonarQube
   - function: test_import_pylint_results
   - purpose: Check that issues revealed by a pylint analysis can be imported in SonarQube.
1. C/C++
   - function: test_language_c_cpp
   - purpose: Check that the C and C++ languages are supported and that CNES Quality Profiles are usable.
1. CppCheck
   - function: test_tool_cppcheck
   - purpose: Check that cppcheck can be launched from within the container to analyze C/C++ projects.
1. Import CppCheck results
   - function: test_import_cppcheck_results
   - purpose: Check that issues revealed by a cppcheck analysis can be imported in SonarQube.

## How to run all the tests

Before testing the image, it must be built with `docker build -t lequal/docker-cat .`.

To run the tests, we use [pytest](https://docs.pytest.org/en/stable/) with `Python 3.8` and the dependencies listed in _requirements.txt_. It is advised to use a virtual environment to run the tests.

```sh
# To run all the tests
$ cd tests/
$ pytest
```

```sh
# One way to set up a virtual environment (optional)
$ cd tests/
$ virtualenv -p python3.8 env
$ . env/bin/activate
$ pip install -r requirements.txt
```

## How to run a specific test

1. Activate the virtual environment (if any)
1. Run a container of the image (see the [user guide](https://github.com/cnescatlab/docker-cat#Quick-install))
1. Wait until it is configured
   - The message `[INFO] Docker CAT is ready to go and find bugs!` is logged.
1. Run a specific test with `pytest` and specify some environment variables

   ```sh
   RUN=no pytest -k "<name of the test>"
   ```

## List of options and environment variables used by the tests

Parameters:

- `--no-run`: if this option is specified, the script will not run the container. It will only launch the tests. In this case, make sur to set necessary environment variables.

Environment variables:

- `RUN`: "no" not to run a container at the start of the tests, the default is to run one.
- `CAT_CONTAINER_NAME`: the name to give to the container running the image.
- `CAT_URL`: URL of `lequal/docker-cat` container if already running without trailing `/` from the host. e.g. <http://localhost:9000>
