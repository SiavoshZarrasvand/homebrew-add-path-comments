# add-path-comments/test/test_add_path_comments.rb
#
# Integration tests: each case builds a throwaway project tree, runs the real
# script against it as a subprocess, and asserts on resulting file contents.
# Assertions deliberately avoid stdout wording so the reporting text stays free
# to change.

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"

SCRIPT = ENV["APC_SCRIPT"] || File.expand_path("../add-path-comments", __dir__)

class PathCommentsTest < Minitest::Test
  # ── Harness ────────────────────────────────────────────────────────────────

  # Yields the project root. The tool derives the comment from the repo
  # directory's own name, so the fixture root is always "myproj".
  def in_project(git: true)
    Dir.mktmpdir do |tmp|
      root = File.join(tmp, "myproj")
      FileUtils.mkdir_p(root)
      File.write(File.join(root, "package.json"), %({"name":"myproj"}\n))
      if git
        Open3.capture2e("git", "-C", root, "init", "-q")
      else
        # find_repo_root walks up looking for .git; without one it would escape
        # the fixture, so give it a marker that is not a real repository.
        FileUtils.mkdir_p(File.join(root, ".git"))
      end
      yield root
    end
  end

  def write(root, rel, content)
    path = File.join(root, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def read(root, rel)
    File.read(File.join(root, rel))
  end

  def run_tool(root, *flags)
    out, status = Open3.capture2e("ruby", SCRIPT, *flags, root)
    [out, status.exitstatus]
  end

  # ── Adding ─────────────────────────────────────────────────────────────────

  def test_adds_missing_comment
    in_project do |root|
      write(root, "lib/foo.ts", "export const a = 1\n")
      _, code = run_tool(root)
      assert_equal 0, code
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1\n", read(root, "lib/foo.ts")
    end
  end

  def test_correct_comment_is_left_untouched
    in_project do |root|
      original = "// myproj/lib/foo.ts\nexport const a = 1\n"
      write(root, "lib/foo.ts", original)
      run_tool(root)
      assert_equal original, read(root, "lib/foo.ts")
    end
  end

  def test_is_idempotent_across_runs
    in_project do |root|
      write(root, "lib/foo.ts", "export const a = 1\n")
      run_tool(root)
      first = read(root, "lib/foo.ts")
      run_tool(root)
      assert_equal first, read(root, "lib/foo.ts")
    end
  end

  def test_file_without_trailing_newline
    in_project do |root|
      write(root, "lib/foo.ts", "export const a = 1")
      run_tool(root)
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1", read(root, "lib/foo.ts")
    end
  end

  # ── Repairing ──────────────────────────────────────────────────────────────

  def test_replaces_wrong_comment_without_stacking
    in_project do |root|
      write(root, "lib/foo.ts", "// myproj/lib/OLD.ts\nexport const a = 1\n")
      run_tool(root)
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1\n", read(root, "lib/foo.ts")
    end
  end

  # The starlight case: a correct line 1 previously masked a stale duplicate,
  # because the old implementation returned as soon as line 1 matched.
  def test_removes_stale_comment_left_below_a_correct_one
    in_project do |root|
      write(root, "components/ticker/tabs.test.tsx",
            "// myproj/components/ticker/tabs.test.tsx\n" \
            "// myproj/components/tabs.test.tsx\n" \
            "import { render } from 'x'\n")
      run_tool(root)
      assert_equal "// myproj/components/ticker/tabs.test.tsx\nimport { render } from 'x'\n",
                   read(root, "components/ticker/tabs.test.tsx")
    end
  end

  def test_moves_comment_that_is_not_on_the_top_line
    in_project do |root|
      write(root, "lib/foo.ts", "// Copyright someone\n// myproj/lib/foo.ts\nexport const a = 1\n")
      run_tool(root)
      assert_equal "// myproj/lib/foo.ts\n// Copyright someone\nexport const a = 1\n",
                   read(root, "lib/foo.ts")
    end
  end

  # Repo renamed: the stale comment names a different project but points at a
  # file with the same extension, so it is still ours to replace.
  def test_replaces_comment_from_a_renamed_repo
    in_project do |root|
      write(root, "lib/foo.ts", "// oldname/lib/foo.ts\nexport const a = 1\n")
      run_tool(root)
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1\n", read(root, "lib/foo.ts")
    end
  end

  def test_collapses_several_stale_comments
    in_project do |root|
      write(root, "lib/foo.ts",
            "// myproj/lib/a.ts\n// myproj/old/foo.ts\n// oldname/lib/foo.ts\nexport const a = 1\n")
      run_tool(root)
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1\n", read(root, "lib/foo.ts")
    end
  end

  # ── Safety ─────────────────────────────────────────────────────────────────

  def test_leaves_prose_comments_alone
    in_project do |root|
      write(root, "lib/foo.ts", "// see lib/other.ts for the sibling impl\nexport const a = 1\n")
      run_tool(root)
      assert_equal "// myproj/lib/foo.ts\n// see lib/other.ts for the sibling impl\nexport const a = 1\n",
                   read(root, "lib/foo.ts")
    end
  end

  # A path-shaped comment below the header block belongs to the code, not us.
  def test_leaves_path_shaped_comment_deeper_in_the_file
    in_project do |root|
      write(root, "lib/foo.ts",
            "export const a = 1\n\n// myproj/lib/bar.ts\nexport const b = 2\n")
      run_tool(root)
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1\n\n// myproj/lib/bar.ts\nexport const b = 2\n",
                   read(root, "lib/foo.ts")
    end
  end

  def test_preserves_shebang
    in_project do |root|
      write(root, "scripts/run.sh", "#!/bin/sh\necho hi\n")
      write(root, "release.sh", "#!/bin/sh\necho release\n")
      run_tool(root)
      assert_equal "#!/bin/sh\n# myproj/scripts/run.sh\necho hi\n", read(root, "scripts/run.sh")
    end
  end

  def test_repairs_below_a_shebang_without_displacing_it
    in_project do |root|
      write(root, "release.sh", "#!/bin/sh\n# myproj/old.sh\necho release\n")
      run_tool(root)
      assert_equal "#!/bin/sh\n# myproj/release.sh\necho release\n", read(root, "release.sh")
    end
  end

  # ── Gitignore ──────────────────────────────────────────────────────────────

  def test_gitignored_files_are_never_touched
    in_project do |root|
      File.write(File.join(root, ".gitignore"), "out/\n")
      write(root, "out/bundle.ts", "export const generated = 1\n")
      write(root, "lib/foo.ts", "export const a = 1\n")
      run_tool(root)
      assert_equal "export const generated = 1\n", read(root, "out/bundle.ts")
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1\n", read(root, "lib/foo.ts")
    end
  end

  def test_gitignored_files_do_not_trip_check
    in_project do |root|
      File.write(File.join(root, ".gitignore"), "out/\n")
      write(root, "out/bundle.ts", "export const generated = 1\n")
      write(root, "lib/foo.ts", "// myproj/lib/foo.ts\nexport const a = 1\n")
      _, code = run_tool(root, "--check")
      assert_equal 0, code
    end
  end

  # Without a usable work tree the tool must still run, falling back to its
  # static exclude list rather than erroring out.
  def test_runs_without_a_git_work_tree
    in_project(git: false) do |root|
      write(root, "lib/foo.ts", "export const a = 1\n")
      _, code = run_tool(root)
      assert_equal 0, code
      assert_equal "// myproj/lib/foo.ts\nexport const a = 1\n", read(root, "lib/foo.ts")
    end
  end

  # ── Check and dry-run ──────────────────────────────────────────────────────

  def test_check_exits_nonzero_when_work_is_pending
    in_project do |root|
      write(root, "lib/foo.ts", "export const a = 1\n")
      _, code = run_tool(root, "--check")
      assert_equal 1, code
    end
  end

  def test_check_exits_zero_when_everything_is_current
    in_project do |root|
      write(root, "lib/foo.ts", "// myproj/lib/foo.ts\nexport const a = 1\n")
      _, code = run_tool(root, "--check")
      assert_equal 0, code
    end
  end

  def test_check_catches_a_stale_duplicate
    in_project do |root|
      write(root, "lib/foo.ts", "// myproj/lib/foo.ts\n// myproj/old/foo.ts\nexport const a = 1\n")
      _, code = run_tool(root, "--check")
      assert_equal 1, code
    end
  end

  def test_check_does_not_modify_files
    in_project do |root|
      original = "export const a = 1\n"
      write(root, "lib/foo.ts", original)
      run_tool(root, "--check")
      assert_equal original, read(root, "lib/foo.ts")
    end
  end

  def test_dry_run_reports_without_modifying_or_failing
    in_project do |root|
      original = "export const a = 1\n"
      write(root, "lib/foo.ts", original)
      out, code = run_tool(root, "--dry-run")
      assert_equal 0, code
      assert_equal original, read(root, "lib/foo.ts")
      assert_includes out, "lib/foo.ts"
    end
  end

  # ── Languages ──────────────────────────────────────────────────────────────

  def test_rust_uses_slash_comments
    in_project do |root|
      File.write(File.join(root, "Cargo.toml"), "[package]\nname = \"myproj\"\n")
      write(root, "src/main.rs", "fn main() {}\n")
      run_tool(root)
      assert_equal "// myproj/src/main.rs\nfn main() {}\n", read(root, "src/main.rs")
    end
  end

  def test_python_uses_hash_comments
    in_project do |root|
      File.write(File.join(root, "pyproject.toml"), "[project]\nname = \"myproj\"\n")
      write(root, "pkg/thing.py", "value = 1\n")
      run_tool(root)
      assert_equal "# myproj/pkg/thing.py\nvalue = 1\n", read(root, "pkg/thing.py")
    end
  end

  # A nested package.json makes the inner directory its own project as well as
  # part of the outer one; its files must still be handled exactly once.
  def test_nested_projects_do_not_process_a_file_twice
    in_project do |root|
      write(root, "tools/mock/package.json", %({"name":"mock"}\n))
      write(root, "tools/mock/index.js", "module.exports = 1\n")
      out, _ = run_tool(root)
      assert_equal 1, out.scan("myproj/tools/mock/index.js").length
      assert_equal "// myproj/tools/mock/index.js\nmodule.exports = 1\n",
                   read(root, "tools/mock/index.js")
    end
  end

  def test_excluded_config_files_are_skipped
    in_project do |root|
      original = "export default {}\n"
      write(root, "next.config.ts", original)
      run_tool(root)
      assert_equal original, read(root, "next.config.ts")
    end
  end

  def test_dot_directories_are_skipped
    in_project do |root|
      original = "export const hidden = 1\n"
      write(root, ".config/thing.ts", original)
      run_tool(root)
      assert_equal original, read(root, ".config/thing.ts")
    end
  end
end
