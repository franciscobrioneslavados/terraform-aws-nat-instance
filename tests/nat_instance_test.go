package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestModuleStructure(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "..",
		NoColor:      true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

func TestModuleFilesExist(t *testing.T) {
	t.Parallel()

	requiredFiles := []string{
		"main.tf",
		"variables.tf",
		"outputs.tf",
		"versions.tf",
		"README.md",
		"LICENSE",
		"examples/basic/main.tf",
		"examples/multi-rt/main.tf",
	}

	for _, file := range requiredFiles {
		filePath := "../" + file
		assert.True(t, files.FileExists(t, filePath), "Required file %s should exist", file)
	}
}

func TestModuleVariables(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "..",
		NoColor:      true,
	}

	plan := terraform.InitAndPlan(t, terraformOptions)

	requiredOutputs := []string{
		"nat_instance_id",
		"nat_instance_arn",
		"nat_instance_public_ip",
		"nat_instance_private_ip",
		"nat_network_interface_id",
		"nat_security_group_id",
		"key_pair_name",
		"ssh_command",
	}

	for _, output := range requiredOutputs {
		outputValue := terraform.Output(t, plan, output)
		assert.NotEmpty(t, outputValue, "Output %s should be defined", output)
	}
}

func TestBasicExample(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/basic",
		NoColor:      true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}

func TestMultiRTExample(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/multi-rt",
		NoColor:      true,
	}

	terraform.Init(t, terraformOptions)
	terraform.Validate(t, terraformOptions)
}
