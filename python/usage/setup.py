from setuptools import setup, find_packages

setup(
    name="usage-proto",
    version="v0.0.5",
    packages=find_packages(),
    install_requires=[
        "grpcio>=1.50.0",
        "protobuf>=4.21.0",
    ],
    python_requires=">=3.11",
)
