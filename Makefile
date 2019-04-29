export PATH := $(HOME)/.local/bin:$(PATH)

all: venv/jhalfs/bin/jhalfs
	@. venv/jhalfs/bin/activate; jhalfs -r

venv/jhalfs/bin/jhalfs: venv/jhalfs
	@. venv/jhalfs/bin/activate; pip install -e .

venv/jhalfs: venv/virtualenv.tamp
	@virtualenv -p python3 venv/jhalfs

venv/virtualenv.stamp:
	@install -d venv
	@command -v virtualenv >/dev/null || pip3 install --user virtualenv
	@touch venv/virtualenv.stamp
