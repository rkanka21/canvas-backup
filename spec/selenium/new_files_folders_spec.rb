require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')

describe "better_file_browsing, folders" do
   include_context "in-process server selenium tests"

  context "Folders" do
    before(:each) do
      course_with_teacher_logged_in
      get "/courses/#{@course.id}/files"
      folder_name = "new test folder"
      add_folder(folder_name)
    end

    it "should display the new folder form", priority: "1", test_id: 268052 do
      click_new_folder_button
      expect(f("form.ef-edit-name-form")).to be_displayed
    end

    it "should create a new folder", priority: "1", test_id: 133121 do
      expect(fln("new test folder")).to be_present
    end

    it "should display all cog icon options", priority: "1", test_id: 133124 do
      create_new_folder
      ff('.al-trigger')[0].click
      expect(fln("Download")).to be_displayed
      expect(fln("Rename")).to be_displayed
      expect(fln("Move")).to be_displayed
      expect(fln("Delete")).to be_displayed
    end

    it "should edit folder name", priority: "1", test_id: 223501 do
      folder_rename_to = "test folder"
      edit_name_from_cog_icon(folder_rename_to)
      wait_for_ajaximations
      expect(fln("new test folder")).not_to be_present
      expect(fln("test folder")).to be_present
    end

    it "should delete a folder from cog icon", priority: "1", test_id: 223502 do
      delete(0, :cog_icon)
      expect(fln("new test folder")).not_to be_present
    end

    it "should unpublish and publish a folder from cloud icon", priority: "1", test_id: 220354 do
      set_item_permissions(:unpublish, :cloud_icon)
      expect(f('.btn-link.published-status.unpublished')).to be_displayed
      expect(driver.find_element(:class => 'unpublished')).to be_displayed
      set_item_permissions(:publish, :cloud_icon)
      expect(f('.btn-link.published-status.published')).to be_displayed
      expect(driver.find_element(:class => 'published')).to be_displayed
    end

    it "should make folder available to student with link", priority: "1", test_id: 133110 do
      set_item_permissions(:restricted_access, :available_with_link, :cloud_icon)
      expect(f('.btn-link.published-status.hiddenState')).to be_displayed
      expect(driver.find_element(:class => 'hiddenState')).to be_displayed
    end

    it "should make folder available to student within given timeframe", priority: "1", test_id: 193160 do
      set_item_permissions(:restricted_access, :available_with_timeline, :cloud_icon)
      expect(f('.btn-link.published-status.restricted')).to be_displayed
      expect(driver.find_element(:class => 'restricted')).to be_displayed
    end

    it "should delete folder from toolbar", priority: "1", test_id: 133105 do
      delete(0, :toolbar_menu)
      expect(get_all_files_folders.count).to eq 0
    end

    it "should be able to create and view a new folder with uri characters", priority: "2", test_id: 193153 do
      folder_name = "this#could+be bad? maybe"
      add_folder(folder_name)
      folder = @course.folders.where(:name => folder_name).first
      expect(folder).to_not be_nil
      file_name = "some silly file"
      att = @course.attachments.create!(:display_name => file_name, :uploaded_data => default_uploaded_data, :folder => folder)
      folder_link = fln(folder_name, f('.ef-directory'))
      expect(folder_link).to be_present
      folder_link.click
      wait_for_ajaximations
      # we should be viewing the new folders contents
      file_link = fln(file_name, f('.ef-directory'))
      expect(file_link).to be_present
    end
  end

  context "Folder Tree" do
     before(:each) do
       course_with_teacher_logged_in
       get "/courses/#{@course.id}/files"
     end

     it "should create a new folder", priority: "2", test_id: 133121 do
       new_folder = create_new_folder
       expect(get_all_files_folders.count).to eq 1
       expect(new_folder.text).to match /New Folder/
     end

     it "should handle duplicate folder names", priority: "1", test_id: 133130 do
       create_new_folder
       add_folder("New Folder")
       expect(get_all_files_folders.last.text).to match /New Folder 2/
     end

     it "should create 15 new child folders and show them in the FolderTree when expanded", priority: "2", test_id: 121886 do
       create_new_folder
       f('.ef-name-col > a.media').click
       wait_for_ajaximations
       1.upto(15) do |number_of_folders|
        folder_regex = number_of_folders > 1 ? Regexp.new("New Folder\\s#{number_of_folders}") : "New Folder"
        create_new_folder
        expect(get_all_files_folders.count).to eq number_of_folders
        expect(get_all_files_folders.last.text).to match folder_regex
       end
       get "/courses/#{@course.id}/files"
       f('ul.collectionViewItems > li > a > i.icon-mini-arrow-right').click
       wait_for_ajaximations
       keep_trying_until { expect(driver.find_elements(:css, 'ul.collectionViewItems > li > ul.treeContents > li.subtrees > ul.collectionViewItems li').count).to eq 15 }
     end
  end
end