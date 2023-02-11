from setuptools import setup
import os

USE_MYPYC = False
if os.getenv('ROSETTABOY_USE_MYPYC', None) == '1':
    USE_MYPYC = True

ext_modules = []
if USE_MYPYC:
    from mypyc.build import mypycify
    ext_modules=mypycify(
        ['src']
    )

setup(
    name='rosettaboy',
    description='A sample Python package',
    packages=['src'],
    install_requires=[
        'pysdl2',
    ],
    entry_points={
        'console_scripts': [
            'rosettaboy-py=src:main.cli_main',
        ],
    },
    ext_modules=ext_modules,
)
