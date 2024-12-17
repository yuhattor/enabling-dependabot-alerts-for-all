# GitHub Dependabot Alert Enabler

A shell script to enable vulnerability alerts across multiple repositories in GitHub organizations or enterprises.

## Prerequisites

- [GitHub CLI](https://cli.github.com/) installed and authenticated
- [jq](https://stedolan.github.io/jq/) command-line JSON processor
- Appropriate GitHub permissions to enable security features

## Usage

```bash
./main.sh <target_name> <scope>
```

### Parameters

- `target_name`: (Required) The name of the organization or enterprise
- `scope`: (Optional) Either "org" or "enterprise". Defaults to "org"

### Examples

Enable vulnerability alerts for a single organization:
```bash
./main.sh my-organization org
```

Enable vulnerability alerts for all organizations in an enterprise:
```bash
./main.sh my-enterprise enterprise
```

## Features

- Supports both organization and enterprise-level operations
- Handles pagination for large organizations/enterprises
- Filters out archived and disabled repositories
- Removes duplicate repositories
- Provides error handling for API failures
- Cleans up temporary files automatically

## API Operations

The script performs the following GitHub API operations:

1. Fetches organizations (for enterprise scope)
2. Retrieves active repositories for each organization
3. Enables vulnerability alerts for each repository

## Error Handling

- Validates input parameters
- Reports API errors during vulnerability alert enablement
- Provides descriptive error messages

## Limitations

- Requires GitHub CLI authentication
- Processes up to 100 items per page (GitHub API limitation)
- Temporary files (`orgs.tmp` and `repos.tmp`) are created during execution

## License

This project is available under the MIT License.
