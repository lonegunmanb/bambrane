package e2e

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/ahmetb/go-linq/v3"
	"github.com/google/go-github/v42/github"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_helper "github.com/lonegunmanb/terraform-module-test-helper"
	"github.com/stretchr/testify/assert"
	_ "github.com/stretchr/testify/assert"
	"golang.org/x/oauth2"
)

func TestExamplesRepoRunner(t *testing.T) {
	owner := os.Getenv("REPO_OWNER")
	if owner == "" {
		t.Skip("To run this test please setup environment variable `REPO_OWNER` first.")
	}
	repo := os.Getenv("REPO")
	if repo == "" {
		t.Skip("To run this test please setup environment variable `REPO` first.")
	}
	personalToken := os.Getenv("GH_TOKEN")
	if personalToken == "" {
		t.Skip("To run this test please setup environment variable `GH_TOKEN` first. The token must has admin permission to the repo.")
	}
	test_helper.RunE2ETest(t, "../../", "examples/repo", terraform.Options{
		Upgrade: true,
		Vars: map[string]interface{}{
			"github_repos": []string{
				fmt.Sprintf("https://github.com/%s/%s", owner, repo),
			},
			"github_access_token": personalToken,
		},
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: personalToken},
		)
		tc := oauth2.NewClient(ctx, ts)

		client := github.NewClient(tc)
		time.Sleep(time.Minute)

		runners, _, err := client.Actions.ListRunners(context.TODO(), owner, repo, &github.ListOptions{
			Page:    0,
			PerPage: 10,
		})
		if err != nil {
			assert.Fail(t, err.Error())
		}
		anyActiveRunner := linq.From(runners.Runners).Where(func(i interface{}) bool {
			r := i.(*github.Runner)
			return *r.Status == "online"
		}).Any()
		assert.True(t, anyActiveRunner, "Cannot find online runner.")
	})
}

func TestExampleOrgRunner(t *testing.T) {
	personalToken := os.Getenv("GH_TOKEN")
	if personalToken == "" {
		t.Skip("To run this test please setup environment variable `GH_TOKEN` first. The token must has admin permission to the repo.")
	}
	org := os.Getenv("ORG")
	if org == "" {
		t.Skip("To run this test please setup environment variable `ORG` first. The token must has OWNER permission to the repo.")
	}
	test_helper.RunE2ETest(t, "../../", "examples/org", terraform.Options{
		Upgrade: true,
		Vars: map[string]interface{}{
			"github_org":          org,
			"github_access_token": personalToken,
		},
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		ctx := context.Background()
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: personalToken},
		)
		tc := oauth2.NewClient(ctx, ts)

		client := github.NewClient(tc)
		time.Sleep(time.Minute)

		runners, _, err := client.Actions.ListOrganizationRunners(context.TODO(), org, &github.ListOptions{
			Page:    0,
			PerPage: 10,
		})
		if err != nil {
			assert.Fail(t, err.Error())
		}

		anyActiveRunner := linq.From(runners.Runners).Where(func(i interface{}) bool {
			r := i.(*github.Runner)
			return *r.Status == "online"
		}).Any()
		assert.True(t, anyActiveRunner, "Cannot find online runner.")
	})
}
