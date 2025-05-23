# X86Flower

This project is a simple Windows application written in x86 assembly (NASM syntax) that displays an animated flower.

## Prerequisites

-   **NASM Assembler**: You'll need NASM to assemble the `.asm` file into an object file. You can download it from [nasm.us](https://www.nasm.us/). Make sure it's added to your system's PATH.
-   **GoLink Linker**: You'll need GoLink to link the object file with Windows libraries and create the executable. You can find GoLink (often `GoLink.exe`) from [godevtool.com](http://www.godevtool.com/). Make sure it's accessible from your PATH or place it in the project directory.

## Building and Running

1.  **Open your terminal** (e.g., PowerShell or Command Prompt) in the project's root directory (`C:\Projects\3DFlowerX86`).

2.  **Create a build directory** (if it doesn't exist):
    ```powershell
    if (-not (Test-Path .\build -PathType Container)) { New-Item -ItemType Directory -Path .\build }
    ```

3.  **Assemble the code** using NASM:
    ```powershell
    nasm -f win32 hello.asm -o build\hello.obj
    ```

4.  **Link the object file** using GoLink:
    ```powershell
    GoLink /entry:WinMain build\hello.obj user32.dll kernel32.dll gdi32.dll build\hello.exe
    ```
    *   `/entry WinMain`: Specifies `WinMain` as the application entry point.
    *   `build\hello.obj`: The input object file.
    *   `user32.dll kernel32.dll gdi32.dll`: Essential Windows libraries.
    *   `/out build\hello.exe`: Specifies the output executable name and path.

5.  **Run the application**:
    ```powershell
    .\build\hello.exe
    ```

This will launch a window displaying the animated flower.
