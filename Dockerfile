FROM public.ecr.aws/lambda/python:3.12-arm64

# Set environment variables
ENV TEXTRACT_CACHE_URI=s3://textractor-cache/
ENV PYTHONPATH="${LAMBDA_TASK_ROOT}"

# Define wheel package as build argument
ARG WHEEL_PACKAGE=flytta_toolbox-0.0.4-py3-none-any.whl

# Copy and install Python dependencies first (for better layer caching)
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r requirements.txt

# Copy and install custom wheel package
COPY .devcontainer/${WHEEL_PACKAGE} ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir ${LAMBDA_TASK_ROOT}/${WHEEL_PACKAGE} && \
    rm ${LAMBDA_TASK_ROOT}/${WHEEL_PACKAGE}

# Copy function code (done last to maximize cache efficiency)
COPY src/ ${LAMBDA_TASK_ROOT}/

# Set the CMD to your handler
CMD ["lambda_function.lambda_handler"]