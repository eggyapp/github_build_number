Usage
---
When compiled as a self-contained executable run the following command for usage instructions:
```shell
./versioning 
```

Building
---
### Cross-platform binary (requires dart to execute)
```shell
trash build && mkdir build && dart compile kernel -o build/versioning.dill bin/main.dart
```

### Arch specific self-contained binary
This method is not recommended since it will only run on the machine you use to compile it.

From the project root run:
```shell
mkdir build && dart compile exe -o build/versioning bin/main.dart
```