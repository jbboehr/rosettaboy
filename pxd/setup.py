#!/usr/bin/env python3

from setuptools import setup, Extension
from Cython.Build import cythonize

setup(
    scripts=["main.py"],
    ext_modules=cythonize(
        module_list=[Extension(name="*", sources=["src/*.py"], libraries=["SDL2"])],
        annotate=True,
        compiler_directives={
            "language_level": 3,
            "profile": True,
            "annotation_typing": True,
        },
        include_path=["src", "include"],
    ),
)
