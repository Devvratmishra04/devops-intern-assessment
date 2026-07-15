#!/usr/bin/env python3
"""
MLflow Experiment Tracker - Extra Credit
Logs a dummy ML experiment with parameters, metrics, and artifacts.
"""

import mlflow


def run_experiment():
    # Set experiment name
    mlflow.set_experiment("devops-intern-demo")

    with mlflow.start_run(run_name="dummy-model-v1"):
        # Log parameters
        mlflow.log_param("model_type", "linear_regression")
        mlflow.log_param("learning_rate", 0.01)
        mlflow.log_param("epochs", 100)

        # Simulate training and log metrics over epochs
        for epoch in range(1, 11):
            loss = 1.0 / epoch
            accuracy = 1.0 - loss
            mlflow.log_metric("loss", loss, step=epoch)
            mlflow.log_metric("accuracy", accuracy, step=epoch)

        # Log final metrics
        mlflow.log_metric("final_loss", 0.1)
        mlflow.log_metric("final_accuracy", 0.9)

        # Log a simple text artifact
        with open("model_summary.txt", "w") as f:
            f.write("Model: Linear Regression\n")
            f.write("Final Loss: 0.1\n")
            f.write("Final Accuracy: 0.9\n")
        mlflow.log_artifact("model_summary.txt")

        print("MLflow experiment logged successfully!")
        print(f"Run ID: {mlflow.active_run().info.run_id}")


if __name__ == "__main__":
    run_experiment()
