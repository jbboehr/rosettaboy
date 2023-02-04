from setuptools import setup
import os
from mypyc.build import mypycify

USE_MYPYC = False
if os.getenv('ROSETTABOY_USE_MYPYC', None) == '1':
    USE_MYPYC = True

ext_modules = []
if USE_MYPYC:
    ext_modules=mypycify([
        'src',
    ]),

setup(
    name='rosettaboy',
    description='A sample Python package',
    packages=['rosettaboy'],
    package_dir={'rosettaboy': 'src'},
    install_requires=[
        'pysdl2',
        'black',
        'mypy',
    ],
    py_modules=['rosettaboy.main'],
    entry_points={
        'console_scripts': [
            'rosettaboy-py=rosettaboy:main.cli_main',
        ],
    },
    ext_modules=ext_modules,
)
