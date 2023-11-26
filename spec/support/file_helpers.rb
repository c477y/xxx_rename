# frozen_string_literal: true

module FileHelpers
  def create_dir(*paths)
    path = File.join("test_folder", *paths)
    FileUtils.mkdir_p(path)
    path
  end

  def create_file(dir, file)
    FileUtils.touch(File.join(dir, file))
    File.join(dir, file)
  end
end
