Run the demo from python notebook

## Setup

### 1. Install python dependencies.

```bash
pip install -r ./requirements.txt
```

### 2. Configure environment variables

Ensure your infrastructure is deployed. Configure the environment variables by making a copy of the `.env.example` file and rename the copied file to `.env`. 

Please refer to [configure environment variables](../demo-app/Readme.md#2-configure-environment-variables) document for detailed description of each environment variable. `Note`, you don't need to configure the `BLOB_SAS_TOKEN` environment variable to run the notebook as in this case your Azure identity will be used for authorization to download the images. That also means, your identity needs to have appropriate permissions the access those images in your Azure blob.

### 3. Notebook Server
Make sure you have the notebook server installed and running. Commonly [jupyter](https://docs.jupyter.org/en/latest/running.html) is used for that.

## Run the demo

Open the `demo.ipynb` file and run the code.
