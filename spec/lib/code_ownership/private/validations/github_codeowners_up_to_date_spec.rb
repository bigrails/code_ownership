module CodeOwnership
  RSpec.describe Private::Validations::GithubCodeownersUpToDate do
    describe 'CodeOwnership.validate!' do
      let(:codeowners_validation) { Private::Validations::GithubCodeownersUpToDate }

      context 'run with autocorrect' do
        before do
          write_configuration
        end

        context 'in an empty application' do
          it 'automatically regenerates the codeowners file' do
            expect(codeowners_path).to_not exist
            expect_any_instance_of(codeowners_validation).to receive(:`).with("git add #{codeowners_path}")
            expect { CodeOwnership.validate! }.to_not raise_error
            expect(codeowners_path.read).to eq <<~EXPECTED
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners

            EXPECTED
          end
        end

        context 'in an non-empty application' do
          before { create_non_empty_application }

          it 'automatically regenerates the codeowners file' do
            expect(codeowners_path).to_not exist
            expect_any_instance_of(codeowners_validation).to receive(:`).with("git add #{codeowners_path}")
            expect { CodeOwnership.validate! }.to_not raise_error
            expect(codeowners_path.read).to eq <<~EXPECTED
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team
              /packs/my_pack/owned_file.rb @MyOrg/bar-team

              # Team-specific owned globs
              /app/services/bar_stuff/** @MyOrg/bar-team
              /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

              # Owner in .codeowner
              /directory/owner/**/** @MyOrg/bar-team
              /directory/owner/(my_folder)/**/** @MyOrg/foo-team

              # Owner metadata key in package.yml
              /packs/my_other_package/**/** @MyOrg/bar-team

              # Owner metadata key in package.json
              /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
              /config/teams/foo.yml @MyOrg/foo-team
            EXPECTED
          end

          context 'the user has passed in specific input files into the validate method' do
            it 'still automatically regenerates the codeowners file, since we look at all files when regenerating CODEOWNERS' do
              expect(codeowners_path).to_not exist
              expect_any_instance_of(codeowners_validation).to receive(:`).with("git add #{codeowners_path}")
              expect { CodeOwnership.validate! }.to_not raise_error
              expect(codeowners_path.read).to eq <<~EXPECTED
                # STOP! - DO NOT EDIT THIS FILE MANUALLY
                # This file was automatically generated by "bin/codeownership validate".
                #
                # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
                # teams. This is useful when developers create Pull Requests since the
                # code/file owner is notified. Reference GitHub docs for more details:
                # https://help.github.com/en/articles/about-code-owners


                # Annotations at the top of file
                /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team
                /packs/my_pack/owned_file.rb @MyOrg/bar-team

                # Team-specific owned globs
                /app/services/bar_stuff/** @MyOrg/bar-team
                /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

                # Owner in .codeowner
                /directory/owner/**/** @MyOrg/bar-team
                /directory/owner/(my_folder)/**/** @MyOrg/foo-team

                # Owner metadata key in package.yml
                /packs/my_other_package/**/** @MyOrg/bar-team

                # Owner metadata key in package.json
                /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

                # Team YML ownership
                /config/teams/bar.yml @MyOrg/bar-team
                /config/teams/foo.yml @MyOrg/foo-team
              EXPECTED
            end
          end

          context 'team does not have a github team listed' do
            before do
              write_file('config/teams/bar.yml', <<~CONTENTS)
                name: Bar
                owned_globs:
                  - app/services/bar_stuff/**
                  - frontend/javascripts/bar_stuff/**
              CONTENTS
            end

            it 'does not include the team in the output' do
              expect(codeowners_path).to_not exist
              expect { CodeOwnership.validate! }.to_not raise_error
              expect_any_instance_of(codeowners_validation).to_not receive(:`)
              expect(codeowners_path.read).to eq <<~EXPECTED
                # STOP! - DO NOT EDIT THIS FILE MANUALLY
                # This file was automatically generated by "bin/codeownership validate".
                #
                # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
                # teams. This is useful when developers create Pull Requests since the
                # code/file owner is notified. Reference GitHub docs for more details:
                # https://help.github.com/en/articles/about-code-owners


                # Owner in .codeowner
                /directory/owner/(my_folder)/**/** @MyOrg/foo-team

                # Team YML ownership
                /config/teams/foo.yml @MyOrg/foo-team
              EXPECTED
            end
          end

          context 'team has chosen to not be added to CODEOWNERS' do
            before do
              write_file('config/teams/bar.yml', <<~CONTENTS)
                name: Bar
                github:
                  team: '@MyOrg/bar-team'
                  do_not_add_to_codeowners_file: true
                owned_globs:
                  - app/services/bar_stuff/**
                  - frontend/javascripts/bar_stuff/**
              CONTENTS
            end

            it 'does not include the team in the output' do
              expect(codeowners_path).to_not exist
              expect { CodeOwnership.validate! }.to_not raise_error
              expect_any_instance_of(codeowners_validation).to_not receive(:`)
              expect(codeowners_path.read).to eq <<~EXPECTED
                # STOP! - DO NOT EDIT THIS FILE MANUALLY
                # This file was automatically generated by "bin/codeownership validate".
                #
                # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
                # teams. This is useful when developers create Pull Requests since the
                # code/file owner is notified. Reference GitHub docs for more details:
                # https://help.github.com/en/articles/about-code-owners


                # Annotations at the top of file
                # /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team
                # /packs/my_pack/owned_file.rb @MyOrg/bar-team

                # Team-specific owned globs
                # /app/services/bar_stuff/** @MyOrg/bar-team
                # /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

                # Owner in .codeowner
                # /directory/owner/**/** @MyOrg/bar-team
                /directory/owner/(my_folder)/**/** @MyOrg/foo-team

                # Owner metadata key in package.yml
                # /packs/my_other_package/**/** @MyOrg/bar-team

                # Owner metadata key in package.json
                # /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

                # Team YML ownership
                # /config/teams/bar.yml @MyOrg/bar-team
                /config/teams/foo.yml @MyOrg/foo-team
              EXPECTED
            end
          end
        end

        context 'run without staging changes' do
          before do
            write_configuration
          end

          it 'does not stage the changes to the codeowners file' do
            expect(codeowners_path).to_not exist
            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(stage_changes: false) }.to_not raise_error
            expect(codeowners_path.read).to eq <<~EXPECTED
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners

            EXPECTED
          end
        end
      end

      context 'run without autocorrect' do
        before do
          write_configuration
        end

        context 'in an empty application' do
          it 'automatically regenerates the codeowners file' do
            expect(codeowners_path).to_not exist
            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
            expect(codeowners_path).to_not exist
          end
        end

        context 'in an non-empty application' do
          before { create_non_empty_application }

          it 'automatically regenerates the codeowners file' do
            expect(codeowners_path).to_not exist
            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
            expect(codeowners_path).to_not exist
          end

          context 'team does not have a github team listed' do
            before do
              write_file('config/teams/bar.yml', <<~CONTENTS)
                name: Bar
                owned_globs:
                  - app/services/bar_stuff/**
                  - frontend/javascripts/bar_stuff/**
              CONTENTS
            end

            it 'does not include the team in the output' do
              expect(codeowners_path).to_not exist
              expect_any_instance_of(codeowners_validation).to_not receive(:`)
              expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
                expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
                expect(e.message).to eq <<~EXPECTED.chomp
                  CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                  See https://github.com/rubyatscale/code_ownership#README.md for more details
                EXPECTED
              end
              expect(codeowners_path).to_not exist
            end
          end

          context 'team has chosen to not be added to CODEOWNERS' do
            before do
              write_file('config/teams/bar.yml', <<~CONTENTS)
                name: Bar
                github:
                  team: '@MyOrg/bar-team'
                  do_not_add_to_codeowners_file: true
                owned_globs:
                  - app/services/bar_stuff/**
                  - frontend/javascripts/bar_stuff/**
              CONTENTS
            end

            it 'does not include the team in the output' do
              expect(codeowners_path).to_not exist
              expect_any_instance_of(codeowners_validation).to_not receive(:`)
              expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
                expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
                expect(e.message).to eq <<~EXPECTED.chomp
                  CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                  See https://github.com/rubyatscale/code_ownership#README.md for more details
                EXPECTED
              end
              expect(codeowners_path).to_not exist
            end
          end
        end

        context 'in an application with a CODEOWNERS file that is missing lines and has extra lines' do
          before { create_non_empty_application }

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team
              /frontend/some/extra/line/that/should/not/exist @MyOrg/bar-team

              # Team-specific owned globs
              /app/services/bar_stuff/** @MyOrg/bar-team
              /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

              # Some extra comment that should not be here

              # Owner metadata key in package.json
              /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                CODEOWNERS should contain the following lines, but does not:
                - "/packs/my_pack/owned_file.rb @MyOrg/bar-team"
                - "/config/teams/foo.yml @MyOrg/foo-team"
                - "# Owner in .codeowner"
                - "/directory/owner/**/** @MyOrg/bar-team"
                - "/directory/owner/(my_folder)/**/** @MyOrg/foo-team"
                - "# Owner metadata key in package.yml"
                - "/packs/my_other_package/**/** @MyOrg/bar-team"

                CODEOWNERS should not contain the following lines, but it does:
                - "/frontend/some/extra/line/that/should/not/exist @MyOrg/bar-team"
                - "# Some extra comment that should not be here"

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
          end
        end

        context 'in an application with a CODEOWNERS file that has extra lines' do
          before { create_non_empty_application }

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team
              /packs/my_pack/owned_file.rb @MyOrg/bar-team
              /frontend/some/extra/line/that/should/not/exist @MyOrg/bar-team

              # Team-specific owned globs
              /app/services/bar_stuff/** @MyOrg/bar-team
              /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

              # Owner in .codeowner
              /directory/owner/**/** @MyOrg/bar-team
              /directory/owner/(my_folder)/**/** @MyOrg/foo-team

              # Owner metadata key in package.yml
              /packs/my_other_package/**/** @MyOrg/bar-team

              # Some extra comment that should not be here

              # Owner metadata key in package.json
              /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
              /config/teams/foo.yml @MyOrg/foo-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                CODEOWNERS should not contain the following lines, but it does:
                - "/frontend/some/extra/line/that/should/not/exist @MyOrg/bar-team"
                - "# Some extra comment that should not be here"

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
          end
        end

        context 'in an application with a CODEOWNERS file that has missing lines' do
          before { create_non_empty_application }

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team

              # Team-specific owned globs
              /app/services/bar_stuff/** @MyOrg/bar-team
              /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

              # Owner metadata key in package.json
              /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                CODEOWNERS should contain the following lines, but does not:
                - "/packs/my_pack/owned_file.rb @MyOrg/bar-team"
                - "/config/teams/foo.yml @MyOrg/foo-team"
                - "# Owner in .codeowner"
                - "/directory/owner/**/** @MyOrg/bar-team"
                - "/directory/owner/(my_folder)/**/** @MyOrg/foo-team"
                - "# Owner metadata key in package.yml"
                - "/packs/my_other_package/**/** @MyOrg/bar-team"

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
          end
        end

        context 'in an application with a CODEOWNERS file with no issue' do
          before { create_non_empty_application }

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team
              /packs/my_pack/owned_file.rb @MyOrg/bar-team

              # Owner in .codeowner
              /directory/owner/**/** @MyOrg/bar-team
              /directory/owner/(my_folder)/**/** @MyOrg/foo-team

              # Owner metadata key in package.yml
              /packs/my_other_package/**/** @MyOrg/bar-team

              # Team-specific owned globs
              /app/services/bar_stuff/** @MyOrg/bar-team
              /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

              # Owner metadata key in package.json
              /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
              /config/teams/foo.yml @MyOrg/foo-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to_not raise_error
          end
        end

        context 'in an application with an unsorted CODEOWNERS file' do
          before { create_non_empty_application }

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /packs/my_pack/owned_file.rb @MyOrg/bar-team
              /frontend/javascripts/packages/my_package/owned_file.jsx @MyOrg/bar-team

              # Owner in .codeowner
              /directory/owner/**/** @MyOrg/bar-team
              /directory/owner/(my_folder)/**/** @MyOrg/foo-team

              # Owner metadata key in package.yml
              /packs/my_other_package/**/** @MyOrg/bar-team

              # Team-specific owned globs
              /app/services/bar_stuff/** @MyOrg/bar-team
              /frontend/javascripts/bar_stuff/** @MyOrg/bar-team

              # Owner metadata key in package.json
              /frontend/javascripts/packages/my_other_package/**/** @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
              /config/teams/foo.yml @MyOrg/foo-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                There may be extra lines, or lines are out of order.
                You can try to regenerate the CODEOWNERS file from scratch:
                1) `rm .github/CODEOWNERS`
                2) `bin/codeownership validate`

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
          end
        end

        context 'in an application with a CODEOWNERS file that has a reference to a github team that no longer exists' do
          before do
            write_configuration

            write_file('packs/my_pack/owned_file.rb', <<~CONTENTS)
              # @team Bar
            CONTENTS

            write_file('config/teams/bar.yml', <<~CONTENTS)
              name: Bar
              github:
                team: '@MyOrg/bar-team'
            CONTENTS
          end

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /packs/my_pack/owned_file.rb @MyOrg/this-team-does-not-exist
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                CODEOWNERS should contain the following lines, but does not:
                - "/packs/my_pack/owned_file.rb @MyOrg/bar-team"
                - "# Team YML ownership"
                - "/config/teams/bar.yml @MyOrg/bar-team"

                CODEOWNERS should not contain the following lines, but it does:
                - "/packs/my_pack/owned_file.rb @MyOrg/this-team-does-not-exist"

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
          end
        end

        context 'in an application with a CODEOWNERS file that has a reference to a file that no longer exists' do
          before do
            write_configuration

            write_file('packs/my_pack/owned_file.rb', <<~CONTENTS)
              # @team Bar
            CONTENTS

            write_file('config/teams/bar.yml', <<~CONTENTS)
              name: Bar
              github:
                team: '@MyOrg/bar-team'
            CONTENTS
          end

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /packs/my_pack/owned_file.rb @MyOrg/bar-team
              /packs/my_pack/deleted_file.rb @MyOrg/bar-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                CODEOWNERS should contain the following lines, but does not:
                - "# Team YML ownership"
                - "/config/teams/bar.yml @MyOrg/bar-team"

                CODEOWNERS should not contain the following lines, but it does:
                - "/packs/my_pack/deleted_file.rb @MyOrg/bar-team"

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
          end
        end

        context 'in an application with a CODEOWNERS file that has a reference to a file that has had an annotation removed' do
          before do
            write_configuration

            write_file('packs/my_pack/had_annotation_file.rb', '')

            write_file('config/teams/bar.yml', <<~CONTENTS)
              name: Bar
              github:
                team: '@MyOrg/bar-team'
            CONTENTS
          end

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners

              # Annotations at the top of file
              /packs/my_pack/had_annotation_file.rb @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false) }.to raise_error do |e|
              expect(e).to be_a CodeOwnership::InvalidCodeOwnershipConfigurationError
              expect(e.message).to eq <<~EXPECTED.chomp
                Some files are missing ownership:

                - packs/my_pack/had_annotation_file.rb

                CODEOWNERS out of date. Run `bin/codeownership validate` to update the CODEOWNERS file

                CODEOWNERS should not contain the following lines, but it does:
                - "# Annotations at the top of file"
                - "/packs/my_pack/had_annotation_file.rb @MyOrg/bar-team"

                See https://github.com/rubyatscale/code_ownership#README.md for more details
              EXPECTED
            end
          end
        end

        context 'validating codeowners using --diff in an application with a CODEOWNERS file' do
          before do
            write_configuration

            write_file('packs/my_pack/had_annotation_file.rb', <<~CONTENTS)
              # @team Bar
            CONTENTS

            write_file('config/teams/bar.yml', <<~CONTENTS)
              name: Bar
              github:
                team: '@MyOrg/bar-team'
            CONTENTS
          end

          it 'prints out the diff' do
            FileUtils.mkdir('.github')
            codeowners_path.write <<~CODEOWNERS
              # STOP! - DO NOT EDIT THIS FILE MANUALLY
              # This file was automatically generated by "bin/codeownership validate".
              #
              # CODEOWNERS is used for GitHub to suggest code/file owners to various GitHub
              # teams. This is useful when developers create Pull Requests since the
              # code/file owner is notified. Reference GitHub docs for more details:
              # https://help.github.com/en/articles/about-code-owners


              # Annotations at the top of file
              /packs/my_pack/had_annotation_file.rb @MyOrg/bar-team

              # Team YML ownership
              /config/teams/bar.yml @MyOrg/bar-team
            CODEOWNERS

            expect_any_instance_of(codeowners_validation).to_not receive(:`)
            expect { CodeOwnership.validate!(autocorrect: false, files: []) }.to_not raise_error
          end
        end
      end

      context 'code_ownership.yml has skip_codeowners_validation set' do
        before do
          write_configuration('skip_codeowners_validation' => true)
        end

        it 'skips validating the codeowners file' do
          expect(codeowners_path).to_not exist
          expect_any_instance_of(codeowners_validation).to_not receive(:`)
          expect { CodeOwnership.validate!(autocorrect: false) }.to_not raise_error
          expect(codeowners_path).to_not exist
        end
      end
    end

    describe 'uniqueness of github teams' do
      context 'when the CodeTeam has a github.team key' do
        before do
          write_configuration

          write_file('config/teams/bar.yml', <<~CONTENTS)
            name: Bar
            github:
              team: '@MyOrg/bar-team'
          CONTENTS

          write_file('config/teams/foo.yml', <<~CONTENTS)
            name: Bar
            github:
              team: '@MyOrg/bar-team'
          CONTENTS
        end

        it 'expect code teams validations to fail' do
          expect(CodeTeams.validation_errors(CodeTeams.all)).to eq([
                                                                     'More than 1 definition for Bar found',
                                                                     "The following teams are specified multiple times:\nEach code team must have a unique GitHub team in order to write the CODEOWNERS file correctly.\n\n@MyOrg/bar-team\n"
                                                                   ])
        end
      end

      context 'when the CodeTeam does not have a github.team key' do
        before do
          write_configuration

          write_file('config/teams/bar.yml', <<~CONTENTS)
            name: Bar
          CONTENTS

          write_file('config/teams/foo.yml', <<~CONTENTS)
            name: Bar
          CONTENTS
        end

        it 'does not report CodeTeams without github.teams key' do
          expect(CodeTeams.validation_errors(CodeTeams.all)).to eq([
                                                                     'More than 1 definition for Bar found'
                                                                   ])
        end
      end
    end

    describe 'require_github_teams configuration option' do
      before do
        write_configuration('require_github_teams' => require_github_teams)

        write_file('config/teams/foo.yml', <<~CONTENTS)
          name: Foo
        CONTENTS

        write_file('config/teams/bar.yml', <<~CONTENTS)
          name: Bar
        CONTENTS
      end

      context 'when require_github_teams is enabled' do
        let(:require_github_teams) { true }

        it 'reports CodeTeams without github.team keys' do
          errors = CodeTeams.validation_errors(CodeTeams.all)
          expect(errors.length).to eq(1)
          expect(errors.first).to include('The following teams are missing `github.team` entries:')
          expect(errors.first).to include('config/teams/bar.yml')
          expect(errors.first).to include('config/teams/foo.yml')
        end
      end

      context 'when require_github_teams is disabled' do
        let(:require_github_teams) { false }

        it 'does not report any errors' do
          expect(CodeTeams.validation_errors(CodeTeams.all)).to be_empty
        end
      end
    end
  end
end
