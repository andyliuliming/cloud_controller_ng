module VCAP::CloudController
  class DockerURIConverter
    class BLAHHALKJASLKJ < StandardError; end

    def convert(docker_uri)
      raise BLAHHALKJASLKJ.new 'akldsfj' if docker_uri.include? '://'
      remote_name, tag = parse_docker_repo_url docker_uri
      Addressable::URI.new(scheme: 'docker', host: '', path: remote_name, fragment: tag).to_s
    end

    def parse_docker_repo_url docker_uri
      name_parts = docker_uri.split('/', 2)

      remote_name = docker_uri

      unless remote_name.index '/'
        remote_name = 'library/' + remote_name
      end

      remote_name, tag = parse_docker_repository_tag remote_name

      [remote_name, tag]
    end

    # func convertDockerURI(dockerURI string) (string, error) {
    #   if strings.Contains(dockerURI, "://") {
    #     return "", errors.New("docker URI [" + dockerURI + "] should not contain scheme")
    #   }
    #
    #     indexName, remoteName, tag := parseDockerRepoUrl(dockerURI)
    #
    #     return (&url.URL{
    #       Scheme:   DockerScheme,
    #         Path:     indexName + "/" + remoteName,
    #         Fragment: tag,
    #     }).String(), nil
    #     }

    # func parseDockerRepoUrl(dockerURI string) (indexName, remoteName, tag string) {
    #   nameParts := strings.SplitN(dockerURI, "/", 2)
    #
    # if officialRegistry(nameParts) {
    #   // URI without host
    #   indexName = ""
    #   remoteName = dockerURI
    #
    #   // URI has format docker.io/<path>
    #     if nameParts[0] == DockerIndexServer {
    #       indexName = DockerIndexServer
    #       remoteName = nameParts[1]
    #     }
    #
    #       // Remote name contain no '/' - prefix it with "library/"
    #       // via https://github.com/docker/docker/blob/a271eaeba224652e3a12af0287afbae6f82a9333/registry/config.go#L343
    #       if strings.IndexRune(remoteName, '/') == -1 {
    #         remoteName = "library/" + remoteName
    #       }
    #       } else {
    #         indexName = nameParts[0]
    #       remoteName = nameParts[1]
    #       }
    #
    #       remoteName, tag = parseDockerRepositoryTag(remoteName)
    #
    #       return indexName, remoteName, tag
    #       }

    def parse_docker_repository_tag(remote_name)
      path, tag = remote_name.split(':', 2)

      unless tag && tag.include?('/')
        return [path, tag]
      end

      [remote_name, '']
    end

    # func parseDockerRepositoryTag(remoteName string) (string, string) {
    #   n := strings.LastIndex(remoteName, ":")
    # if n < 0 {
    #   return remoteName, ""
    # }
    # if tag := remoteName[n+1:]; !strings.Contains(tag, "/") {
    #   return remoteName[:n], tag
    # }
    # return remoteName, ""
    # }
  end
end
