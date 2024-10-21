@isTest
private class DocumentoControllerTest {

    @TestSetup
    static void makeData() {
        doCreateData();
    }
    
    private static void doCreateData() {

        Map<String, RecordType> recordTypes = new Map<String, RecordType>();
        Set<String> recordTypeTypes = new Set<String>{'Account', 'Contact'};

        Profile profile = [SELECT Id FROM Profile WHERE (Name = 'Usuário Padrão') OR (Name = 'Standard User') LIMIT 1];

        User user = new User(
            Alias = 'TestUser',
            Email = 'test@email.com',
            EmailEncodingKey = 'ISO-8859-1',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            UserName = 'test240920241005@email.com',
            profileId = profile.Id
        );

        insert user;

        for (RecordType rt : [SELECT DeveloperName FROM RecordType WHERE SobjectType IN :recordTypeTypes]) {
            recordTypes.put(rt.DeveloperName, rt);
        }

        List<Account> accounts = new List<Account>{
            new Account(
                Name = 'Account',
                CNPJ__c = '45246904000130',
                DDICelular__c = 'Brasil (+55)',
                DDDCelular__c = '16',
                Celular__c = '18845-6789',
                DDITelefone__c = 'Brasil (+55)',
                DDDTelefone__c = '11',
                Phone = '12345-6789'   
            ),
            new Account(
                Name = 'Corretor 1',
                CNPJ__c = '55181736000103',
                DDICelular__c = 'Brasil (+55)',
                DDDCelular__c = '16',
                Celular__c = '18805-6789',
                DDITelefone__c = 'Brasil (+55)',
                DDDTelefone__c = '15',
                Phone = '36259-6789'   
            ),
            new Account(
                Name = 'Corretor 2',
                CNPJ__c = '35635456000102',
                DDICelular__c = 'Brasil (+55)',
                DDDCelular__c = '16',
                Celular__c = '18845-0089',
                DDITelefone__c = 'Brasil (+55)',
                DDDTelefone__c = '12',
                Phone = '96857-6789'   
            )
        };
        
        insert accounts;

        Empreendimento__c empreendimento = new Empreendimento__c(
            Name = 'Empreendimento Teste',
            CNPJ__c = '10155540000106'
        );

        insert empreendimento;

        Bloco__c bloco = new Bloco__c(
            Name = 'Torre A',
            Empreendimento__c = empreendimento.Id
        );

        insert bloco;

        Product2 unidade = new Product2(
            Name = 'Unidade',
            Bloco__c = bloco.Id,
            NumeroDaUnidade__c = 1
        );

        insert unidade;

        
        List<Contact> corretores = new List<Contact>{
            new Contact(
                FirstName = 'Corretor',
                LastName = 'A',
                RecordTypeId = recordTypes.get('Corretor').Id,
                AccountId = accounts.get(1).Id,
                Celular__c = '36251-6363',      
                DDDCelular__c = '11',          
                DDICelular__c = 'Brasil (+55)',
                Phone = '78747-5252',           
                DDDTelefone__c = '21',          
                DDITelefone__c = 'Brasil (+55)'
            ),
            new Contact(
                FirstName = 'Corretor',
                LastName = 'B',
                RecordTypeId = recordTypes.get('Corretor').Id,
                AccountId = accounts.get(1).Id,
                Celular__c = '85856-6363',      
                DDDCelular__c = '11',          
                DDICelular__c = 'Brasil (+55)',
                Phone = '74145-3524',           
                DDDTelefone__c = '21',          
                DDITelefone__c = 'Brasil (+55)'
            )
        };
    
        insert corretores;
        
        List<Opportunity> opportunities = new List<Opportunity>{
            new Opportunity(
                Name = 'Oportunidade 1',
                StageName = 'Proposta',
                CloseDate = System.today().addMonths(1),
                AccountId = accounts.get(1).Id,
                ResponsavelPeloLead__c = user.Id
            ),
            new Opportunity(
                Name = 'Oportunidade 2',
                StageName = 'Proposta',
                CloseDate = System.today().addMonths(2),
                Unidade__c = unidade.Id,
                AccountId = accounts.get(0).Id,
                Corretor__c = corretores.get(0).Id,
                ResponsavelPeloLead__c = user.Id
            )
        };

        insert opportunities;
        

        List<AnaliseDeCredito__c> analisesDeCredito = new List<AnaliseDeCredito__c>{
            new AnaliseDeCredito__c(
                    Oportunidade__c = opportunities.get(0).Id
                ),
            new AnaliseDeCredito__c(
                    Oportunidade__c = opportunities.get(1).Id
            )
        };

        insert analisesDeCredito;
    }

    @isTest
    static void documentosPorCompradorEmOportunidadeTest() {
        Id oportunidadeId = [SELECT Id FROM Opportunity LIMIT 1][0].Id;

        Test.startTest();
        Map<String, List<Documento__c>> documentosPorCompradorEmOportunidade = DocumentoController.documentosPorCompradorEmOportunidade(oportunidadeId);
        Test.stopTest();

        Assert.isFalse(documentosPorCompradorEmOportunidade.isEmpty());
    }

    @isTest
    private static void documentosPorAnaliseCreditoTest() {
        Id analiseCreditoId = [SELECT Id FROM AnaliseDeCredito__c LIMIT 1][0].Id;

        Test.startTest();
        Map<String, List<Documento__c>> documentosPorAnaliseCredito = DocumentoController.documentosPorAnaliseCredito(analiseCreditoId);
        Test.stopTest();

        Assert.isFalse(documentosPorAnaliseCredito.isEmpty());
    }

    @isTest
    private static void atualizarStatusDocumentoTest() {
        // {"a06be000002LXj2AAG":"Aprovado"}

        List<Documento__c> documentos = [SELECT Id, StatusAprovacao__c FROM Documento__c LIMIT 2];

        Map<Id, String> mapStatusPorIdDocumento = new Map<Id, String>();
        for (Documento__c documento : documentos) {
            mapStatusPorIdDocumento.put(documento.Id, 'Entregue');
            anexarDocumento(documento.Id);
        }
        
        Test.startTest();
        DocumentoController.atualizarStatusDocumento(mapStatusPorIdDocumento);
        Test.stopTest();

        List<Documento__c> documentosAtualizados = [SELECT Id, StatusAprovacao__c FROM Documento__c];

        Assert.areEqual(documentosAtualizados[0].StatusAprovacao__c, 'Entregue');
        Assert.areEqual(documentosAtualizados[1].StatusAprovacao__c, 'Entregue');
        Assert.areEqual(documentosAtualizados[2].StatusAprovacao__c, 'Não Entregue');
    }

    private static void anexarDocumento(Id linkedEntityId) {
        String base64 = 'dGVzdGU=';
        String fileName = 'arquivo.txt';
        String fileType = 'text/plain';

        ContentVersion cv = new ContentVersion(
            VersionData = EncodingUtil.base64Decode(base64),
            Title = filename,
            PathOnClient = filename
        );
        
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId,
            LinkedEntityId = linkedEntityId,
            ShareType = 'V'
        );

        insert cdl;  
    }
}