require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

describe_provider :vcsrepo, :hg, :resource => {:path => '/tmp/vcsrepo'} do

  describe 'creating' do
    resource_with :source do
      resource_with :revision do
        it "should execute 'hg clone -u' with the revision" do
          provider.expects(:hg).with('clone', '-u',
                                      resource.value(:revision),
                                      resource.value(:source),
                                      resource.value(:path))
          provider.create
        end        
      end
      
      resource_without :revision do
        it "should just execute 'hg clone' without a revision" do
          provider.expects(:hg).with('clone', resource.value(:source), resource.value(:path))
          provider.create
        end        
      end
    end
    
    context "when a source is not given" do
      it "should execute 'hg init'" do
        provider.expects(:hg).with('init', resource.value(:path))
        provider.create
      end
    end
  end

  describe 'destroying' do
    it "it should remove the directory" do
      expects_rm_rf
      provider.destroy
    end
  end

  describe "checking existence" do
    it "should check for the directory" do
      expects_directory?(true, File.join(resource.value(:path), '.hg'))
      provider.exists?
    end
  end

  describe "checking the revision property" do
    before do
      expects_chdir
    end
    
    context "when given a non-SHA as the resource revision" do
      before do
        provider.expects(:hg).with('parents').returns(fixture(:hg_parents))
        provider.expects(:hg).with('tags').returns(fixture(:hg_tags))
      end
      
      context "when its SHA is not different than the current SHA", :resource => {:revision => '0.6'} do
        it "should return the ref" do
          provider.revision.should == '0.6'
        end
      end
      
      context "when its SHA is different than the current SHA", :resource => {:revision => '0.5.3'} do
        it "should return the current SHA" do
          provider.revision.should == '34e6012c783a'
        end          
      end
    end
    context "when given a SHA as the resource revision" do
      before do
        provider.expects(:hg).with('parents').returns(fixture(:hg_parents))
      end
      
      context "when it is the same as the current SHA", :resource => {:revision => '34e6012c783a'} do
        it "should return it" do
          provider.expects(:hg).with('tags').never
          provider.revision.should == resource.value(:revision)
        end
      end
      
      context "when it is not the same as the current SHA", :resource => {:revision => 'not-the-same'} do
        it "should return the current SHA" do
          provider.expects(:hg).with('tags').returns(fixture(:hg_tags))
          provider.revision.should == '34e6012c783a'
        end
      end
    end
  end
  
  describe "setting the revision property" do
    before do
      @revision = '6aa99e9b3ab1'
    end
    it "should use 'hg update ---clean -r'" do
      expects_chdir
      provider.expects('hg').with('pull')
      provider.expects('hg').with('merge')
      provider.expects('hg').with('update', '--clean', '-r', @revision)
      provider.revision = @revision
    end
  end

end
