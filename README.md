# Alpha

Alpha is a tool based on [Rascal](https://www.rascal-mpl.org/) for parsing C++ code and producing M3 models in JSON. These models contain rich information about the source code, such as information about variables, functions, classes, templates, etc., and the dependencies between such elements. These models can then be used as input for [M3GraphBuilder](https://github.com/Software-Analytics-Visualisation-Team/M3GraphBuilder), which produces graphs for visualizing the source code structure in ClassViz, ARViSAN, and BubbleTeaViz.

# Table of Contents

- [Getting Started with Alpha](#getting-started-with-alpha)
- [Running Alpha](#running-alpha)
    - [Prerequisites](#prerequisites)
    - [Running Locally](#running-locally)
        - [Running with the Rascal Jar (Recommended)](#running-with-the-rascal-jar-recommended)
        - [Running Alpha in VSCode](#running-alpha-in-vscode)
        - [Running Alpha with Maven](#running-alpha-with-maven)
    - [Running in Docker](#running-in-docker)
- [Configuration](#configuration)
- [Alpha Input](#alpha-input)
- [Parsing files and modules](#parsing-files-and-modules)
- [License](#license)
- [Contributions](#contributions)
- [Support](#support)

# Getting Started with Alpha

To start parsing C++ with Alpha, follow these steps. The sections below contain more information about the separate steps.

1. Clone the repository.
2. Prepare your input. Create three text files which will contain the paths to the cpp files to be parsed, the included headers, and standard libraries used in the cpp files. Section "**Alpha Input**" contains instructions on preparing the input.
3. Set the path to the input folder in the Alpha config. Section **Configuration** describes the values in the configuration. 
3. Start Alpha using one of the methods described in the **Running Alpha** section below.
4. Run `main(moduleName = "MyFirstParsedModel");` to parse the C++ source code you want.


# Running Alpha

To parse C++ code with Alpha, you can either run Alpha locally (recommended) or in a Docker container.

## Prerequisites

Before running Alpha using one of the methods described below, clone this repository and ensure you have the following installed:
- Java Development Kit (JDK) 8 or higher (to run with the Alpha Rascal jar, and Maven)
- VSCode (to run Alpha in VSCode)
- Apache Maven (to run Alpha with Maven)
- Docker (for running Alpha in Docker)

## Running Locally

Since Alpha is written in Rascal, to run it locally, you require Rascal in some form. Below, we describe how to run Rascal using the Rascal jar (the simplest), with Maven, or with VSCode. Running it with Rascal jar or in VSCode are the most straightforward and recommended ways. For other ways of running Rascal, refer to [Getting Started with Rascal](https://www.rascal-mpl.org/docs/GettingStarted/RunningRascal/).

### Running with the Rascal Jar (Recommended)

1. **Download the Rascal standalone jar**: Download the jar file from [Rascal Download and Installation](https://www.rascal-mpl.org/docs/GettingStarted/DownloadAndInstallation/) in the `alpha-rascal` folder.
1. **Start Rascal REPL**: Open a command line in the `alpha-rascal` folder and run the command `java -jar rascal-shell-stable.jar` to start a Rascal read-eval-print-loop (REPL). The repository contains the Rascal jar, but if you prefer, you can download the latest stable jar from the [Rascal website](https://www.rascal-mpl.org/docs/GettingStarted/DownloadAndInstallation/).
2. **Import Alpha**: In the Rascal REPL, run `import Parser;` to import Alpha in the Rascal REPL. You've successfully started Alpha.

### Running Alpha in VSCode

1. **Install VSCode Rascal Extension**: Open VSCode, and open the Extensions tab (Ctrl+Shift+X). Search for 'Rascal Metaprogramming Language' in the search field and install the extension.
2. **Open Alpha Folder**: Open the `alpha-rascal` folder with VSCode.
3. **Load Alpha**: Select the `Parser.rsc` file and click on 'Import in new Rascal terminal' on top of the file to load Alpha into Rascal. A Rascal terminal will appear within VSCode with Alpha imported in it. You've successfully started Alpha in VSCode.

### Running Alpha with Maven
1. **Start Rascal Console**: Open a new command line in the `alpha-rascal` folder and run the command `mvn rascal:console`. You've successfully started Alpha with Maven.

## Running in Docker

Running Alpha in Docker comes with several caveats and is currently *not* recommended. If you choose to run Alpha in Docker, make sure to clone the Alpha repository, the C++ code you want to parse, and all of its dependencies (e.g., C++ standard libraries, etc.) on the same drive. This is important as the Dockerized application needs access to these files to parse the C++ code properly. Furthermore, make sure that none of the paths for the inputs contain whitespace (e.g., "Program Files (x86)"). If the path to input files contains such spaces, Rascal will not be able to handle them properly within the Docker container.

1. **Configure Docker**: Open `alpha-rascal/config.json` and change the value of `inDocker` to `true`.
2. **Build Docker Image**: Open a command line in the `alpha-rascal` folder and run the command `docker build . -t alpha-rascal` to create an image of Alpha.
3. **Run Docker Container**: Run the command `docker run -it -v "C:/:/app/host" -v "C:/Development/Alpha/alpha-rascal/input:/app/input" -v "C:/Development/Alpha/alpha-rascal/models:/app/models" alpha-rascal` to create a Docker container (a running instance of Alpha) from the image you just created.

# Configuration

The `config.json` file in the `alpha-rascal` folder contains configuration settings for Alpha. Below are the descriptions of the values in the `config.json` file:

- **inputFolderAbsolutePath**: A string value that indicates the absolute path to the folder which contains the input text files for Alpha. We recommend creating an `input` folder and separate folders within, if you are going to parse several different systems.
- **saveFilesAsJson**: A boolean value that indicates whether Alpha should save the output models as json. If set to `false` the M3 models will be saved as binary files. The recommended format is json as it is human readable.
- **composeModels**: A boolean value that indicates whether Alpha should create a composed json containing information about the entire system that was parsed. Set this to `false` if you only want M3 models for separate cpp files, otherwise set it to `true`. Beware that the composed models can be very large based on the system that you are parsing.
- **verbose**: A boolean value that indicates how much information should be outputed while Alpha. Set this to `true` if you are interested in extra information, otherwise set it to `false`.
- **inDocker**: A boolean value that indicates whether Alpha is running inside a Docker container. Set this to `true` if you are running Alpha in Docker, otherwise set it to `false`.
- **localDrive**: A string value containing the drive letter for the drive containing Alpha. Set this if you intend to run Alpha in a Docker container, otherwise it can remain empty.
- **saveUnresolvedIncludes**: A boolean value that indicates whether Alpha should output lists of unresolved includes. Set to `true` initially to see which include directories and standard library directories could not be resolved during parsing. When set to `true` the `models` (i.e., output) folder will contain an `unresolved` folder. In it you can find lists of unresolved header files (per cpp file). Add the paths to these files in the input to improve the quality of the parsed models.

Example `config.json`:
```json
{
    "inputFolderAbsolutePath": "C:/Development/Alpha/alpha-rascal/input",
    "saveFilesAsJson": true,
    "composeModels": true,
    "verbose": true,
    "inDocker": false,
    "localDrive": "C:",
    "saveUnresolvedIncludes": true
}
```

# Alpha Input
Alpha requires three text files as input, described below. These files need to be placed in the `input` folder or a subfolder within `input`. The repository contains three example files. Add the absolute path to your input folder in the `config.json`:

- **cpp-files.txt**: Contains the list of C++ source files to be parsed.
- **include-dirs.txt**: Contains the list of directories to search for include files.
- **std-libs.txt**: Contains the list of standard library directories.
- **modules-files.txt** (Optional): Contains the list of module files to be processed.

# Parsing files and modules
When running Alpha with a module name, (e.g., `main(moduleName = "MyFirstParsedModel");`) Alpha will parse all the C++ files listed in the `cpp-files.txt` and produce models for each of them in the models folder. Depending on the Alpha configuration, a composed model and the unresolved headers will also be output. If the system you are parsing contains several distinct parts or modules, such as a Visual Studio solution with multiple projects, they can be parsed separately. You can parse the modules separately by creating a text file for each module and then indicating the paths to these text files in the `modules-files.txt`. To process all modules, leave the moduleName parameter empty: `main()`;

# License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

# Contributions

We welcome contributions to Alpha! If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Commit your changes (`git commit -am 'Add new feature'`).
5. Push to the branch (`git push origin feature-branch`).
6. Create a new Pull Request.

Please ensure your code follows the project's coding standards and includes appropriate tests.

# Support

If you encounter any issues or have questions about Alpha, please open an issue on the [GitHub repository](https://github.com/Software-Analytics-Visualisation-Team/Alpha/issues). We will do our best to assist you.