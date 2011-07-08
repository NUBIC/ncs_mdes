require File.expand_path("../../../spec_helper.rb", __FILE__)

module NcsNavigator::Mdes
  describe SourceDocuments do
    before do
      @spec_base, ENV[SourceDocuments::BASE_ENV_VAR] = ENV[SourceDocuments::BASE_ENV_VAR], nil
    end

    after do
      ENV[SourceDocuments::BASE_ENV_VAR] = @spec_base
    end

    describe '#base' do
      let(:base) { SourceDocuments.new.base }

      it 'defaults to the documents directory in the gem' do
        base.should == File.expand_path('../../../../documents', __FILE__)
      end

      it 'can be overridden using the NCS_MDES_DOCS_DIR environment variable' do
        ENV['NCS_MDES_DOCS_DIR'] = '/etc/foo'
        base.should == '/etc/foo'
      end
    end

    describe '#schema' do
      let(:docs) { SourceDocuments.new }

      before do
        docs.base = '/baz'
      end

      it 'absolutizes a relative path against the base' do
        docs.schema = '1.3/bar.xsd'
        docs.schema.should == '/baz/1.3/bar.xsd'
      end

      it 'leaves an absolute path alone' do
        docs.schema = '/somewhere/particular.xsd'
        docs.schema.should == '/somewhere/particular.xsd'
      end
    end

    describe '.get' do
      describe '1.2' do
        subject { SourceDocuments.get('1.2') }

        it 'has the correct path for the schema' do
          subject.schema.should =~ %r{1.2/Data_Transmission_Schema_V1.2.xsd$}
        end

        it 'is of the specified version' do
          subject.version.should == '1.2'
        end
      end

      describe '2.0' do
        subject { SourceDocuments.get('2.0') }

        it 'has the correct path for the schema' do
          subject.schema.should =~ %r{2.0/NCS_Transmission_Schema_2.0.01.02.xml$}
        end

        it 'is of the specified version' do
          subject.version.should == '2.0'
        end
      end

      it 'fails for an unsupported version' do
        lambda { SourceDocuments.get('1.0') }.
          should raise_error('MDES 1.0 is not supported by this version of ncs_mdes')
      end
    end

    describe '.xmlns' do
      subject { SourceDocuments.xmlns }

      it 'includes the XSD namespace' do
        subject['xs'].should == 'http://www.w3.org/2001/XMLSchema'
      end

      it 'includes the NCS namespace' do
        subject['ncs'].should == 'http://www.nationalchildrensstudy.gov'
      end

      it 'includes the NCS doc namespace' do
        subject['ncsdoc'].should == 'http://www.nationalchildrensstudy.gov/doc'
      end

      it 'is available from an instance also' do
        SourceDocuments.new.xmlns.keys.sort.should == %w(ncs ncsdoc xs)
      end
    end
  end
end
