{
  repositories: {
    repo: [
      to_entries[] |
      {
        "+@name": .key,
        commit: .value.commit,
        date: .value.date,
        branch: .value.branch,
        fetchedAt: .value.fetchedAt
      }
    ]
  }
}

