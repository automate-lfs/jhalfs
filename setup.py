from setuptools import setup
from codecs import open
from os import path
import subprocess

with open(path.join(path.abspath(path.dirname(__file__)), 'README'),
          encoding='utf-8') as f:
    long_description = f.read()

base_version = '3.0'

try:
    with open('/dev/null', 'w') as err:
        version = subprocess.check_output(
            ['git', 'describe', '--tags'],
            stderr=err).strip().decode().replace('"', '')
except subprocess.CalledProcessError:
    version = '{}.dev'.format(base_version)

rev = subprocess.check_output(['git', 'show', '-s', '--format="%h"'])
rev = rev.strip().decode().replace('"', '')
rev_date = subprocess.check_output(['git', 'show', '-s', '--format="%ci"'])
rev_date = rev_date.strip().decode().replace('"', '')
with open('jhalfs/git-version', 'w') as f:
    f.write('Revision: {}\nDate: {}\n'.format(
        rev, rev_date))

setup(
    name='jhalfs',

    description=('A tool for automated builds of Linux From Scratch '
                 'or similarly structured tasks.'),
    long_description=long_description,

    # The project's main homepage.
    url='https://github.com/automate-lfs/jhalfs',

    # Author details
    author=['the jhalfs team',
            'Jeremy Huntwork',
            'George Boudreau',
            'Manuel Canales Esparcia',
            'Thomas Pegg',
            'Matthew Burgess',
            'Pierre Labastie'
            ],
    license='MIT',

    version=version,
    zip_safe=True,

    # See https://pypi.python.org/pypi?%3Aaction=list_classifiers
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Intended Audience :: Information Technology',
        'Intended Audience :: System Administrators',
        'Topic :: Utilities',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
    ],
    keywords='scripting automation',
    packages=['jhalfs'],
    package_data={'jhalfs': [
        'Config.in',
        '*LFS*/*',
        'BLFS/*/*',
        'common/*',
        'common/libs/*',
        'extras/*',
        'jhalfs.sh',
        'git-version',
        'install-blfs-tools.sh',
        'optimize/*',
        'optimize/*/*',
        'pkgmngt/*'
    ]},
    entry_points={'console_scripts': ['jhalfs=jhalfs:main']},
    install_requires=['lxml>=4.9']
)
